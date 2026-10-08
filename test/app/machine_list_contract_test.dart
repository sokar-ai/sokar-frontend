import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machines.dart';

/// The machine list in `frontend.json` is read by another repository: `sokar-intellij`'s plugin takes
/// `machines[]` with `name`, `socket`, `host` and `remoteSocket`. A rename here
/// is a break there, so it is said in the channel first, and this test is what makes it deliberate.
void main() {
  test('a machine reached through a tunnel is stored with the four fields the plugin reads', () {
    const machine = Machine(
        name: 'walk9',
        socketPath: '/run/user/1000/sokar-tunnel-walk9.sock',
        host: 'walk9@192.168.122.174',
        remoteSocket: '/run/user/1012/sokar/sokard.sock');

    expect(machine.stored, <String, Object?>{
      'name': 'walk9',
      'socket': '/run/user/1000/sokar-tunnel-walk9.sock',
      'host': 'walk9@192.168.122.174',
      'remoteSocket': '/run/user/1012/sokar/sokard.sock',
    });
  });

  test('a machine somebody else forwards, or this computer, is stored without host and remote socket', () {
    const machine = Machine(name: 'here', socketPath: '/run/user/1000/sokar/sokard.sock');

    expect(machine.stored, <String, Object?>{'name': 'here', 'socket': '/run/user/1000/sokar/sokard.sock'});
    expect(Machine.fromStored(machine.stored).needsATunnel, isFalse);
  });
}
