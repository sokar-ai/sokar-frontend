import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/machines.dart';
import 'package:sokar_frontend/src/app/pty.dart';
import 'package:sokar_frontend/src/app/session.dart';
import 'package:xterm/xterm.dart' show TerminalKey;

/// A prompt that reads a secret shows nothing while it is typed, so the typing is counted — as a
/// number and nothing else — and every key still reaches the far end unchanged.
void main() {
  late _Channel channel;
  late Session session;

  setUp(() {
    channel = _Channel();
    session = Session(
      task: 'vault',
      machine: const Machine(name: 'vm', socketPath: '/tmp/vm.sock'),
      open: (executable, arguments, {int columns = 80, int rows = 24}) => channel,
      run: const <String>['sokar', 'vault', 'unlock'],
    );
  });

  tearDown(() => session.dispose());

  test('each character typed is counted, and reaches the far end as it was typed', () {
    session.terminal.textInput('s3cr');

    expect(session.typedSinceEnter, 4);
    expect(channel.sent.join(), 's3cr');
  });

  test('a backspace takes one back, and Enter starts the count again', () {
    session.terminal.textInput('abc');
    session.terminal.keyInput(TerminalKeyProbe.backspace);
    expect(session.typedSinceEnter, 2);

    session.terminal.keyInput(TerminalKeyProbe.enter);
    expect(session.typedSinceEnter, 0);
  });
}

/// The keys the terminal emulator sends for the two that change the count.
abstract final class TerminalKeyProbe {
  static const backspace = _Key.backspace;
  static const enter = _Key.enter;
}

typedef _Key = TerminalKey;

class _Channel implements SessionChannel {
  final List<String> sent = <String>[];
  final _ended = Completer<int>();

  @override
  Stream<List<int>> get output => const Stream<List<int>>.empty();

  @override
  void send(String input) => sent.add(input);

  @override
  void resize({required int columns, required int rows}) {}

  @override
  Future<int> get ended => _ended.future;

  @override
  Future<void> close() async {
    if (!_ended.isCompleted) _ended.complete(0);
  }
}
