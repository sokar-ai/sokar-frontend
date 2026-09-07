import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machines.dart';
import 'package:sokar_frontend/src/app/settings.dart';

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

  test('an empty value is not a socket path', () {
    final machine = Machine.local(environment: const <String, String>{'SOKAR_SOCKET': ''});

    expect(machine.name, 'this machine');
  });
}
