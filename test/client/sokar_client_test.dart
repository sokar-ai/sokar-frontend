import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/mock/mock_daemon.dart';

/// Drives the real client over a real unix socket against [MockDaemon].
///
/// Over a socket rather than by calling the methods directly: what is being checked is the wire,
/// and a call that never crosses it proves nothing about the framing, the streaming or the
/// disconnect handling - which is all of what is hard here.
void main() {
  late MockDaemon daemon;

  setUp(() async {
    daemon = MockDaemon();
    await daemon.start();
  });

  tearDown(() => daemon.stop());

  Future<SokarClient> connect() => SokarClient.connect(
      Backend(socketPath: daemon.socketPath, label: 'mock'));

  Map<String, dynamic> task(String name, {bool running = true, int helpers = 4}) => {
        'name': name,
        'project': 'demo',
        'securityClass': 'guarded',
        'state': running ? 'Up 2 minutes' : 'Exited (143) 1 second ago',
        'running': running,
        'helpers': helpers,
      };

  group('talking to a backend', () {
    test('reads the task list over the socket', () async {
      daemon.method('List', (_) => {'tasks': [task('sokar-demo-shell-1')]});
      final tasks = await (await connect()).tasks();
      expect(tasks, hasLength(1));
      expect(tasks.single.name, 'sokar-demo-shell-1');
      expect(tasks.single.helpers, 4);
    });

    test('a refusal arrives as an outcome, not as a failure', () async {
      // HOLDS_WORK is the gate working. A client that treated it as an error would show the one
      // answer that matters most as a generic failure.
      daemon.method('Stop', (_) => {
            'outcome': 'HOLDS_WORK',
            'work': '2 commits on main',
            'rescuedRef': '',
            'removed': false,
            'helpers': 0,
            'surviving': 4,
            'detail': '',
          });
      final stopped = await (await connect()).stop('sokar-demo-shell-1');
      expect(stopped.outcome, Outcome.holdsWork);
      expect(stopped.removed, isFalse);
      expect(stopped.work, '2 commits on main');
    });

    test('a named error keeps its name so one refusal can be told from another', () async {
      daemon.fails('Decide', 'org.fuin.sokar.Tasks1.NoClearance', {'task': 'gone'});
      final client = await connect();
      await expectLater(
        client.decide(
            const Prompt(
                task: 'gone',
                key: 'tcp/example.com/443',
                destination: 'example.com',
                protocol: 'tcp',
                port: 443,
                at: '',
                prefix: ''),
            allow: true),
        throwsA(isA<VarlinkException>()
            .having((e) => e.simpleName, 'simpleName', 'NoClearance')),
      );
    });
  });

  group('streaming', () {
    test('a watch delivers every event and then ends', () async {
      daemon.stream('Watch', (_) => Stream.fromIterable([
            {'tasks': [task('a')]},
            {'tasks': [task('a'), task('b')]},
            {'tasks': [task('b')]},
          ]));
      final seen = await (await connect()).watchTasks().toList();
      expect(seen.map((tasks) => tasks.length), [1, 2, 1]);
    });

    test('a stream cut mid-flight is an error, never a quiet end', () async {
      // The requirement is that tunnel loss shows as a disconnection and never as a machine with
      // nothing on it. A stream that completed normally here would render as an empty fleet.
      daemon.stream('Watch', (_) async* {
        yield {'tasks': [task('a')]};
        daemon.severConnections();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        yield {'tasks': [task('b')]};
      });
      final client = await connect();
      await expectLater(client.watchTasks(), emitsThrough(emitsError(anything)));
    });

    test('a stream that ends politely without a final reply is still an error', () async {
      // The subtler half of the same requirement, and the one a passing test can hide. A socket
      // that is destroyed surfaces as a socket error; a connection closed *politely* mid-stream
      // surfaces as the stream just ending, which reads as "nothing is running" rather than as a
      // lost backend. Found by deliberately removing the guard and watching this not fail.
      daemon.hangUpOn.add('Watch');
      await expectLater((await connect()).watchTasks(), emitsError(isA<VarlinkDisconnected>()));
    });

    test('a call whose connection closes before it is answered is an error', () async {
      daemon.hangUpOn.add('List');
      await expectLater((await connect()).tasks(), throwsA(isA<VarlinkDisconnected>()));
    });

    test('a launch streams its output and then its result', () async {
      daemon.stream('Start', (_) => Stream.fromIterable([
            {'line': 'building the image'},
            {'line': 'done'},
            {'container': 'sokar-demo-shell-9', 'exitCode': 0},
          ]));
      final progress = await (await connect()).start(project: 'project.yml').toList();
      expect(progress.take(2).map((p) => p.line), ['building the image', 'done']);
      expect(progress.last.isResult, isTrue);
      expect(progress.last.container, 'sokar-demo-shell-9');
    });
  });

  group('staying compatible with an older backend', () {
    // None of these can be tested against a real daemon: it always has every method it declares,
    // and only ever sends values it knows about. This is why the mock is permanent.

    test('a missing method disables one feature instead of failing the client', () async {
      daemon.method('List', (_) => {'tasks': [task('a')]});
      daemon.remove('Credentials');
      final client = await connect();

      await expectLater(client.credentials(), throwsA(isA<FeatureNotSupported>()));
      // and everything else still works
      expect(await client.tasks(), hasLength(1));
    });

    test('an unrecognised outcome is carried, not thrown on', () async {
      // Adding an enum value is explicitly not a breaking change, so a client that cannot survive
      // one breaks on a routine backend release. A generated Dart enum would throw here.
      daemon.method('Stop', (_) => {
            'outcome': 'QUARANTINED_PENDING_REVIEW',
            'work': '',
            'rescuedRef': '',
            'removed': false,
            'helpers': 0,
            'surviving': 0,
            'detail': '',
          });
      final stopped = await (await connect()).stop('a');
      expect(stopped.outcome.isKnown, isFalse);
      expect(stopped.outcome.name, 'QUARANTINED_PENDING_REVIEW');
      expect(stopped.outcome.label, 'quarantined pending review');
    });

    test('an unrecognised reply field is ignored', () async {
      daemon.method('List', (_) => {
            'tasks': [ {...task('a'), 'somethingAddedLater': 42} ],
            'anotherNewField': true,
          });
      expect(await (await connect()).tasks(), hasLength(1));
    });

    test('the newest understood interface is chosen, not the newest offered', () async {
      daemon.interfaces = const [
        'org.varlink.service',
        'org.fuin.sokar.Tasks1',
        'org.fuin.sokar.Tasks2',
      ];
      // Tasks2 is offered and this build does not know it, so Tasks1 is what gets used - which is
      // what lets an old interface keep working against a new backend.
      expect((await connect()).interfaceName, 'org.fuin.sokar.Tasks1');
    });

    test('a backend serving nothing understood says so plainly', () async {
      daemon.interfaces = const ['org.varlink.service', 'org.fuin.sokar.Tasks9'];
      await expectLater(connect(), throwsA(isA<StateError>()));
    });

    test('the build version is reported but never gates anything', () async {
      daemon.version = '0.9.3';
      expect((await connect()).info.version, '0.9.3');
    });
  });

  group('when there is no backend', () {
    test('an absent socket is a disconnection, not a crash', () async {
      await expectLater(
        SokarClient.connect(
            const Backend(socketPath: '/nonexistent/sokard.sock', label: 'nowhere')),
        throwsA(isA<VarlinkDisconnected>()),
      );
    });
  });

  group('the contract', () {
    test('is read from the running backend rather than a copy', () async {
      daemon.description = 'interface org.fuin.sokar.Tasks1\nmethod List() -> (tasks: []Task)';
      expect(await (await connect()).contract(), contains('method List()'));
    });
  });
}
