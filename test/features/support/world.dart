import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';
import 'package:sokar_frontend/src/app/fleet_model.dart';
import 'package:sokar_frontend/src/app/operations.dart';
import 'package:sokar_frontend/src/app/settings.dart';
import 'package:sokar_frontend/src/app/shell_model.dart';
import 'package:sokar_frontend/src/app/sokar_app.dart';

/// A backend that answers whatever a scenario needs it to.
///
/// Not the mock daemon, and the difference is the point: the mock daemon proves the *client*
/// over a real socket, and it lives in `test/client` where the wire is what is being judged.
/// This proves the *frame*, which is judged on what a person sees — including when the backend
/// refuses, has no `Watch`, or goes away. A widget test runs on a fake clock and real socket
/// input never completes under it, so the frame has to be reachable without one.
class FakeBackend implements FleetBackend {
  /// Constructor taking what the machine has on it.
  FakeBackend(this._tasks);

  List<Task> _tasks;
  final _changes = StreamController<List<Task>>.broadcast();

  /// What `GetInfo` answers.
  ServiceInfo whatItIs = const ServiceInfo(
    product: 'Sokar',
    version: '0.1.0-mock',
    vendor: 'fuin.org',
    interfaces: <String>['org.varlink.service', 'org.fuin.sokar.Tasks1'],
  );

  /// Set to refuse [open], the way a machine with no daemon on it does.
  VarlinkDisconnected? absent;

  /// Set to refuse [watch], the way a backend older than `Watch` does.
  bool withoutWatch = false;

  /// What the most recent [startTask] is printing into.
  ///
  /// The scenario drives it: a line at a time, ended when the scenario says so. Nothing here is
  /// on a clock, or a test of a long operation becomes a test of how fast the machine is.
  late StreamController<String> launch;

  /// How many launches have been asked for, and with what.
  final List<bool> launched = <bool>[];

  @override
  String get label => 'mock';

  @override
  Future<ServiceInfo> open() async {
    final refusal = absent;
    if (refusal != null) throw refusal;
    return whatItIs;
  }

  @override
  Future<List<Task>> tasks() async => _tasks;

  @override
  Stream<List<Task>> watch() async* {
    if (withoutWatch) throw const FeatureNotSupported('Watch');
    yield _tasks;
    yield* _changes.stream;
  }

  @override
  Stream<String> startTask({
    String? task,
    String? project,
    String? agent,
    bool dryRun = false,
  }) {
    launched.add(dryRun);
    launch = StreamController<String>();
    return launch.stream;
  }

  /// Changes what is on the machine, as a backend does when something elsewhere moves.
  void publish(List<Task> tasks) {
    _tasks = tasks;
    _changes.add(tasks);
  }

  /// Stops answering, as a tunnel does.
  void lose() => _changes.addError(const VarlinkDisconnected('the tunnel went away'));

  /// Closes the change stream.
  Future<void> stop() => _changes.close();
}

/// What one scenario's steps share.
class World {
  /// The backend under test.
  static late FakeBackend backend;

  /// Where the appearance is remembered. It survives a restart within a scenario, which is what
  /// makes "still dark after a restart" a real check rather than a re-read of a field.
  static late MemorySettingsStore store;

  /// The interface's own preferences.
  static late Settings settings;

  /// What is on the machine.
  static late FleetModel fleet;

  /// What is open and where the keyboard is.
  static late ShellModel shell;

  /// What this session has run.
  static late Operations operations;

  /// One machine with two projects on it, one of them with work stopped.
  static List<Task> get work => <Task>[
        _task('sokar-checkout-shell', 'checkout'),
        _task('sokar-checkout-migrate', 'checkout', running: false, helpers: 0),
        _task('sokar-billing-shell', 'billing', securityClass: 'offline', helpers: 1),
      ];

  // Built from a wire-shaped map on purpose, so a fixture cannot describe a task the contract
  // could not actually deliver.
  static Task _task(
    String name,
    String project, {
    bool running = true,
    int helpers = 2,
    String securityClass = 'guarded',
  }) =>
      Task.from(<String, dynamic>{
        'name': name,
        'project': project,
        'securityClass': securityClass,
        'state': running ? 'Up 4 minutes' : 'Exited (0) 12 minutes ago',
        'running': running,
        'helpers': helpers,
      });

  /// Puts a backend behind the interface, and closes it when the scenario ends.
  static Future<void> startBackend(List<Task> tasks) async {
    backend = FakeBackend(tasks);
    addTearDown(backend.stop);
  }

  /// Builds the interface against that backend and connects it.
  static Future<void> startApp(WidgetTester tester) async {
    store = MemorySettingsStore();
    settings = Settings(store);
    shell = ShellModel();
    operations = Operations();
    fleet = FleetModel(backend);
    addTearDown(fleet.dispose);
    addTearDown(operations.dispose);

    await tester.pumpWidget(SokarApp(
      fleet: fleet,
      shell: shell,
      settings: settings,
      operations: operations,
    ));
    await fleet.connect();
    await tester.pumpAndSettle();
  }

  /// Closes the window and opens it again, keeping what was stored.
  static Future<void> restartApp(WidgetTester tester) async {
    final reopened = Settings(store);
    await reopened.load();
    settings = reopened;
    shell = ShellModel();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(SokarApp(
      fleet: fleet,
      shell: shell,
      settings: settings,
      operations: operations,
    ));
    await tester.pumpAndSettle();
  }

  /// Redraws until things have stopped moving.
  ///
  /// Not [WidgetTester.pumpAndSettle]: an operation that is still running shows a spinner, and an
  /// animation with no end means pumpAndSettle never returns. Two frames, the second long enough
  /// to carry a dialog transition, is all any of this needs.
  static Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// The theme the interface is actually drawn with.
  static ThemeData themeInUse(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first));
}
