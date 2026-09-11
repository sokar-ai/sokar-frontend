import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

/// Runs this client against a **real** `sokard`.
///
/// Skipped unless one is there, because it needs the whole backend up:
///
/// ```bash
/// sokard &                       # or install the sokar package
/// SOKAR_SOCKET=$XDG_RUNTIME_DIR/sokar/sokard.sock flutter test test/client/live_daemon_test.dart
/// ```
///
/// It is the only test that can say the hand-written client agrees with the daemon rather than
/// with our reading of the IDL. Everything else in this suite runs against a stand-in, and a
/// stand-in only ever proves that the client handles what *we* decided to send it. **A drifted
/// mock is worse than no mock**, and this is what keeps it honest.
void main() {
  final socket = Platform.environment['SOKAR_SOCKET'] ?? '';
  final there = socket.isNotEmpty &&
      (File(socket).existsSync() || Link(socket).existsSync());

  group('against a running daemon', () {
    late SokarClient client;

    setUpAll(() async {
      client = await SokarClient.connect(
          Backend(socketPath: socket, label: 'the live daemon'));
    });

    test('serves an interface this build understands', () async {
      expect(SokarClient.supported, contains(client.interfaceName));
      expect(client.info.version, isNotEmpty);
    });

    test('declares every method this client calls', () async {
      // The drift check. A method renamed or dropped on the far side shows up here as a name this
      // contract no longer contains, rather than as a MethodNotFound in front of somebody.
      final contract = await client.contract();

      for (final method in <String>[
        'List',
        'Watch',
        'Agents',
        'Credentials',
        'Start',
        'Stop',
        'Remove',
        'Tail',
        'Pending',
        'Review',
        'Approve',
        'Reject',
        'Prompts',
        'Decide',
      ]) {
        expect(contract, contains('method $method'),
            reason: '$method is called by this client and is not in the served contract');
      }
    });

    test('answers List with tasks this build can read', () async {
      // Reading them at all is the assertion: every reader tolerates a shape the backend did not
      // promise, so a task that fails to parse here is a contract change, not a bad machine.
      expect(await client.tasks(), isA<List<Task>>());
    });
  },
      skip: there
          ? false
          : 'no daemon: set SOKAR_SOCKET to a running sokard to run these');
}
