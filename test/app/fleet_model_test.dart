import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';
import 'package:sokar_frontend/src/app/fleet_model.dart';

/// A backend that is reachable and useless: the socket opens and nothing is ever answered.
class _Wedged implements FleetBackend {
  @override
  String get label => 'the mock';

  @override
  Future<ServiceInfo> open() async =>
      throw const VarlinkDisconnected('GetInfo was not answered within 5 seconds');

  @override
  Future<List<Task>> tasks() async => const <Task>[];

  @override
  Future<List<Project>> projects() async => const <Project>[];

  @override
  Stream<List<Task>> watch() => const Stream<List<Task>>.empty();

  @override
  Stream<String> startTask({
    String? task,
    String? project,
    String? agent,
    bool dryRun = false,
  }) =>
      const Stream<String>.empty();

  @override
  Future<Stopped> stopTask(
    String task, {
    bool? purge,
    bool? rescue,
    bool? force,
  }) async =>
      throw const VarlinkDisconnected('nothing there');

  @override
  Future<Resumed> resumeTask(String task) async =>
      throw const VarlinkDisconnected('nothing there');

  @override
  Future<List<Log>> logsOf(String task) async => const <Log>[];

  @override
  Stream<List<String>> tailLog(String task, String log) =>
      const Stream<List<String>>.empty();
}

/// A machine that lists one project nothing has ever run on, and one task belonging to a project
/// it does not list at all.
class _Machine implements FleetBackend {
  @override
  String get label => 'the mock';

  @override
  Future<ServiceInfo> open() async => const ServiceInfo(
      product: 'Sokar', version: '0', vendor: 'fuin.org', interfaces: <String>[]);

  @override
  Future<List<Task>> tasks() async => <Task>[
        Task.from(const <String, dynamic>{'name': 'sokar-orphan', 'project': 'vanished'}),
      ];

  @override
  Future<List<Project>> projects() async => <Project>[
        Project.from(const <String, dynamic>{'name': 'never-run', 'tasks': 0}),
      ];

  @override
  Stream<List<Task>> watch() => const Stream<List<Task>>.empty();

  @override
  Stream<String> startTask({
    String? task,
    String? project,
    String? agent,
    bool dryRun = false,
  }) =>
      const Stream<String>.empty();

  @override
  Future<Stopped> stopTask(String task,
          {bool? purge, bool? rescue, bool? force}) async =>
      throw UnimplementedError();

  @override
  Future<Resumed> resumeTask(String task) async => throw UnimplementedError();

  @override
  Future<List<Log>> logsOf(String task) async => const <Log>[];

  @override
  Stream<List<String>> tailLog(String task, String log) =>
      const Stream<List<String>>.empty();
}

void main() {
  test('a backend that never answers reads as not connected, and says why', () async {
    // Otherwise the frame sits on "asking the backend what is here" for ever, which is the one
    // state a person can neither act on nor understand.
    final fleet = FleetModel(_Wedged());

    await fleet.connect();

    expect(fleet.reachability, Reachability.unreachable);
    expect(fleet.status, contains('not answered'));
    fleet.dispose();
  });

  test('a project that has never run anything is listed, and so is orphaned work', () async {
    // Two things a derived list gets wrong in opposite directions: it cannot show a project with
    // no tasks at all, and it would silently drop work whose project the daemon no longer lists.
    final fleet = FleetModel(_Machine());

    await fleet.connect();

    expect(fleet.projects.map((project) => project.name),
        containsAll(<String>['never-run', 'vanished']));
    final vanished =
        fleet.projects.firstWhere((project) => project.name == 'vanished');
    expect(vanished.tasks, hasLength(1));
    expect(vanished.canBeActedOn, isFalse);
    fleet.dispose();
  });
}
