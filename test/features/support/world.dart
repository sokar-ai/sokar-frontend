import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';
import 'package:sokar_frontend/src/app/fleet_model.dart';
import 'package:sokar_frontend/src/app/logs.dart';
import 'package:sokar_frontend/src/app/machines.dart';
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

  /// What `Projects` answers. Assembled by the daemon, so a scenario sets it rather than the
  /// interface deriving it.
  List<Project> theProjectsItHas = <Project>[
    Project.from(const <String, dynamic>{
      'name': 'checkout',
      'securityClass': 'guarded',
      'file': '/srv/checkout/project.yml',
      'mirror': '/srv/checkout/.sokar/mirror',
      'pending': 2,
      'tasks': 2,
      'running': 1,
    }),
    Project.from(const <String, dynamic>{
      'name': 'billing',
      'securityClass': 'offline',
      'file': '/srv/billing/project.yml',
      'mirror': '',
      'pending': 0,
      'tasks': 1,
      'running': 1,
    }),
  ];

  @override
  Future<List<Project>> projects() async => theProjectsItHas;

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

  /// What the next [stopTask] answers. Set by the scenario, so a refusal can be produced without
  /// contriving a task that genuinely holds commits.
  Stopped nextStop = Stopped.from(const <String, dynamic>{
    'outcome': 'STOPPED',
    'work': '',
    'rescuedRef': '',
    'removed': true,
    'helpers': 0,
    'surviving': 0,
    'detail': '',
    'discarded': 128,
  });

  /// What the next [resumeTask] answers.
  Resumed nextResume = Resumed.from(const <String, dynamic>{
    'outcome': 'RESUMED',
    'started': 2,
    'recorded': 2,
    'imageDrift': '',
    'problems': <String>[],
  });

  /// Every stop asked for, and how it was asked.
  final List<({String task, bool? purge, bool? rescue, bool? force})> stops =
      <({String task, bool? purge, bool? rescue, bool? force})>[];

  /// Acts on the machine, rather than only answering about it.
  ///
  /// A stand-in that says a task was removed and goes on listing it makes a working interface
  /// look like one where nothing happens. That was found by hand, against the other stand-in,
  /// with every test green — so both of them act now, and a scenario holds this one to it.
  @override
  Future<Stopped> stopTask(
    String task, {
    bool? purge,
    bool? rescue,
    bool? force,
  }) async {
    stops.add((task: task, purge: purge, rescue: rescue, force: force));
    if (nextStop.removed) {
      _tasks = _tasks.where((each) => each.name != task).toList();
      _changes.add(_tasks);
    }
    return nextStop;
  }

  @override
  Future<Resumed> resumeTask(String task) async => nextResume;

  /// What the next [tailLog] prints into, so the scenario decides when a line arrives.
  late StreamController<List<String>> tailing;

  /// Logs this machine has. What `Logs` answers, and what `Tail` accepts.
  Set<String> theLogsItHas = <String>{'agent.log'};

  @override
  Future<List<Log>> logsOf(String task) async => <Log>[
        for (final name in theLogsItHas)
          Log.from(<String, dynamic>{
            'name': name,
            'bytes': 2048,
            'at': '2026-09-07T14:12:00Z',
          }),
      ];

  @override
  Stream<List<String>> tailLog(String task, String log) {
    tailing = StreamController<List<String>>();
    if (!theLogsItHas.contains(log)) {
      tailing.addError(
          const VarlinkException('org.fuin.sokar.Tasks1.NoSuchLog', <String, dynamic>{}));
      tailing.close();
    }
    return tailing.stream;
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

  /// Every machine being watched, and which one is being acted on.
  static late Machines machines;

  /// What is on the machine being acted on.
  static FleetModel get fleet => machines.fleet;

  /// Another machine, for the scenarios about reaching several.
  static late FakeBackend elsewhere;

  /// What is open and where the keyboard is.
  static late ShellModel shell;

  /// What this session has run.
  static late Operations operations;

  /// What this session is reading.
  static late Logs logs;

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
  ///
  /// At a desktop size, because that is what this is: the default 800x600 test surface is a
  /// narrow window, and every scenario would have been judging the fallback layout by accident.
  static Future<void> startApp(WidgetTester tester) async {
    // The view rather than the surface, at a pixel ratio of one: the surface is set in *physical*
    // pixels, so a default ratio quietly turns a desktop window into a narrow one and every
    // scenario judges the fallback layout without saying so.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store = MemorySettingsStore();
    settings = Settings(store);
    shell = ShellModel();
    operations = Operations();
    logs = Logs();
    elsewhere = FakeBackend(<Task>[_task('sokar-shared-shell', 'shared')]);
    addTearDown(elsewhere.stop);

    // One machine to begin with, and a second only when a scenario asks. Reaching several is
    // F20, and every scenario that does not care must not pay for it.
    machines = Machines(
      settings,
      reach: (machine) => machine.name == 'elsewhere' ? elsewhere : backend,
    );
    await machines.load();
    addTearDown(machines.dispose);
    addTearDown(operations.dispose);
    addTearDown(logs.dispose);

    await tester.pumpWidget(SokarApp(
      machines: machines,
      shell: shell,
      settings: settings,
      operations: operations,
      logs: logs,
    ));
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
      machines: machines,
      shell: shell,
      settings: settings,
      operations: operations,
      logs: logs,
    ));
    await tester.pumpAndSettle();
  }

  /// Redraws until things have stopped moving.
  ///
  /// Not [WidgetTester.pumpAndSettle]: an operation that is still running shows a spinner, and an
  /// animation with no end means pumpAndSettle never returns. Two frames, the second long enough
  /// to carry a dialog transition, is all any of this needs.
  static Future<void> settle(WidgetTester tester) async {
    // Three frames, not two: a theme change animates, and the frame that ends the animation is
    // not the frame that draws its result.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// The theme the interface is actually drawn with.
  static ThemeData themeInUse(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first));
}
