// Runs the mock backend on its own, so the interface can be worked on with no daemon.
// ignore_for_file: avoid_print - this is a command-line tool; printing is its output.
//
// Usage: dart tool/mock_daemon.dart [situation] [socket]
//
//   dart tool/mock_daemon.dart
//   flutter run -d linux
//
// The interface shows a running mock as the machine "mock", beside any it has stored, and never
// stores it. SOKAR_SOCKET moves where it looks.
//
// A second one, to try reaching several machines at once — the interface watches all of them,
// lists each on the rail, and acts on the one whose place is open:
//
//   dart tool/mock_daemon.dart work /tmp/sokar-elsewhere.sock
//
// What it answers is MockMachine, which the tests hold to the same behavior. This file is only
// the socket, the situation and the keyboard.
import 'dart:convert';
import 'dart:io';

import 'package:sokar_frontend/src/mock/machine.dart';
import 'package:sokar_frontend/src/mock/mock_daemon.dart';

/// A name that does not move between runs, so the command to open the interface does not either.
const _defaultSocket = '/tmp/sokar-mock.sock';

Future<void> main(List<String> args) async {
  final situation = args.isEmpty ? 'work' : args.first;
  final stableSocket = args.length > 1 ? args[1] : _defaultSocket;
  if (!MockMachine.situations.containsKey(situation)) {
    stderr.writeln('Unknown situation "$situation". One of:');
    MockMachine.situations
        .forEach((name, what) => stderr.writeln('  ${name.padRight(16)} $what'));
    exitCode = 1;
    return;
  }

  final daemon = MockDaemon();
  await daemon.start();
  final machine = MockMachine(daemon, situation: situation);

  // The daemon picks a fresh temporary path every run, which makes the one instruction anybody
  // needs impossible to copy. A link at a stable name fixes that; a unix socket connects through
  // one unchanged.
  _forget(stableSocket);
  Link(stableSocket).createSync(daemon.socketPath);

  print('mock sokard — ${MockMachine.situations[situation]}');
  print('');
  print('  SOKAR_SOCKET=$stableSocket flutter run -d linux');
  print('');
  print('  RETURN adds a task and pushes the change');
  print('  b blocks a connection, a allows it, d denies it, x lets it run out');
  print('  ctrl-d stops');

  // Asynchronously, and that is not a style choice: stdin.readLineSync() blocks the isolate, so a
  // daemon that waited on it would accept a connection and then never answer a call. It looks
  // exactly like a hung backend, because it is one.
  var added = 0;
  var blocked = 0;
  Map<String, dynamic>? asked;
  final typing = stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    switch (line.trim()) {
      case 'b':
        asked = machine.blocks('api${++blocked}.example.test:443');
        print('blocked api$blocked.example.test:443 — answer it in the interface');
      case 'x':
        if (asked == null) {
          print('nothing is blocked; press b first');
        } else {
          machine.expires(asked!);
          print('that question ran out — it stays blocked and is never asked again');
        }
      default:
        machine.addTask('sokar-checkout-fix-${++added}', 'checkout');
        print('published ${machine.tasks.length} tasks');
    }
  });
  await typing.asFuture<void>();

  await machine.close();
  await daemon.stop();
  _forget(stableSocket);
}

void _forget(String socket) {
  final link = Link(socket);
  if (link.existsSync()) link.deleteSync();
}
