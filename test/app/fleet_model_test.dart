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
}
