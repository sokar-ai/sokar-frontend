import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machines.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/settings.dart';

import '../features/support/world.dart';

/// Which socket the interface opens when nothing has been stored yet.
///
/// One line of code, and it was silently dropped by the rework that made several machines
/// possible: `SOKAR_SOCKET` stopped being read, so the window opened on the local runtime socket
/// and said it could not connect. Every test passed. This is the guard that was missing.
void main() {
  test('SOKAR_SOCKET names the machine to open', () {
    final machine = Machine.local(
      environment: const <String, String>{'SOKAR_SOCKET': '/tmp/sokar-mock.sock'},
    );

    expect(machine.socketPath, '/tmp/sokar-mock.sock');
    expect(machine.name, 'sokar-mock.sock');
  });

  test('without it, the local daemon', () {
    final machine = Machine.local(environment: const <String, String>{});

    expect(machine.name, 'this machine');
    expect(machine.socketPath, endsWith('/sokar/sokard.sock'));
  });

  test('a machine exists before anything has been read back from disk', () {
    // The frame is drawn before load() can finish. A Machines with nothing in it yet crashed the
    // first frame, and the window that came up said it could not connect.
    final machines = Machines(Settings(MemorySettingsStore()));

    expect(machines.all, hasLength(1));
    expect(machines.of(machines.current), isNotNull);
    machines.dispose();
  });

  test('two machines that cannot say which node they are are not the same node', () async {
    // **Absence is not a value.** A daemon older than `Node()` answers nothing, and two machines
    // both saying nothing are not thereby one — which would be the very failure the method
    // exists to prevent, arriving from the other side.
    //
    // Held here rather than in a scenario because the state has to be exact: the local machine
    // records its id as the frame comes up, so a feature step can only ever clear one of the two.
    final machines = Machines(
      Settings(MemorySettingsStore()),
      // The features' own fake, so this is a backend that really answers rather than a stub
      // written to make one assertion pass.
      reach: (machine) => FakeBackend(const <Task>[])..nodeId = '',
      tunnels: FakeTunnels(),
    );
    await machines.add(const Machine(name: 'other', socketPath: '/tmp/other.sock'));
    // Both are connected and both answered nothing, which is the state that matters: one machine
    // could never be the same node as anything.
    await Future<void>.delayed(Duration.zero);

    expect(machines.all, hasLength(2));
    for (final machine in machines.all) {
      expect(machines.nodeOf(machine), isEmpty);
      expect(machines.sameNodeAs(machine), isEmpty);
    }
    machines.dispose();
  });

  test('an empty value is not a socket path', () {
    final machine = Machine.local(environment: const <String, String>{'SOKAR_SOCKET': ''});

    expect(machine.name, 'this machine');
  });
}
