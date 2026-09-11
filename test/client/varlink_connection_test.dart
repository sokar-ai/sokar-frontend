import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/wire/varlink_connection.dart';
import 'package:sokar_frontend/src/wire/varlink_exception.dart';

/// The transport against a peer that goes away, which a forward does when its far end has no
/// socket: ssh accepts the connection here, then hangs up.
void main() {
  late Directory scratch;
  late ServerSocket server;
  late String socketPath;

  setUp(() async {
    scratch = Directory.systemTemp.createTempSync('varlink');
    socketPath = '${scratch.path}/sokard.sock';
    server = await ServerSocket.bind(InternetAddress(socketPath, type: InternetAddressType.unix), 0);
    server.listen((client) => client.destroy());
  });

  tearDown(() async {
    await server.close();
    scratch.deleteSync(recursive: true);
  });

  test('a peer that hangs up is a lost connection, never an error that escapes', () async {
    final connection = await VarlinkConnection.open(socketPath);
    // Written after the peer has gone, so the write itself fails.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await expectLater(
      connection.call('org.fuin.sokar.Tasks1.List'),
      throwsA(isA<VarlinkDisconnected>()),
    );
    // Long enough for a failed write to surface where nobody is waiting for it.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
}
