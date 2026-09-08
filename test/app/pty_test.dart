import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/pty.dart';

/// The terminal, against the real kernel.
///
/// **This is the one thing in this repository that cannot be proven with a fake.** Everything
/// above it is held by the session's own tests; what is here is whether a pty is really a
/// terminal — and the way to know is to ask the far end, in its own words, rather than to assert
/// that this code called the functions it calls.
void main() {
  Future<String> whatItPrinted(Pty pty) =>
      pty.output.transform(utf8.decoder).join();

  test('the far end is a terminal, and knows the size it was given', () async {
    // `stty` fails outright without a controlling terminal, so an answer at all is the proof
    // that one was acquired — and the numbers prove the size arrived. Rows first, as stty says
    // them.
    final pty = Pty.start('sh', <String>['-c', 'stty size'], columns: 100, rows: 30);
    final said = await whatItPrinted(pty);

    expect(said.trim(), '30 100');
    expect(await pty.ended, 0);
  });

  test('a new size reaches what is already running', () async {
    final pty = Pty.start(
      'sh',
      // Waits for a line, so the resize below lands while it is running rather than before it
      // starts — which is the case that matters and the one a fixed size would pass anyway.
      <String>['-c', 'read line; stty size'],
      columns: 80,
      rows: 24,
    );
    final printed = whatItPrinted(pty);

    pty.resize(columns: 132, rows: 43);
    pty.send('go\n');

    expect((await printed).trim().split('\n').last.trim(), '43 132');
  });

  test('what it exits with is what is reported', () async {
    final pty = Pty.start('sh', <String>['-c', 'exit 69']);
    await whatItPrinted(pty);

    // 69 is the code `sokar task attach` refuses with, so this is the number a session reads to
    // tell "it would not open" from "somebody typed exit".
    expect(await pty.ended, 69);
  });

  test('a program that is not there never opens, rather than opening and dying', () async {
    // A shell reports a missing command as exit 127, and this deliberately does not: libc says
    // so before anything runs, so **the missing CLI is a refusal to open** and never a session
    // that appeared for an instant. The two read differently on screen and should.
    expect(
      () => Pty.start('sokar-does-not-exist', const <String>[]),
      throwsA(isA<PtyRefused>().having((refused) => refused.words, 'words',
          contains('no `sokar-does-not-exist` on this machine'))),
    );
  });

  test('what is typed reaches it, and what it prints comes back', () async {
    final pty = Pty.start('sh', <String>['-c', 'read line; echo "heard: \$line"']);
    final printed = whatItPrinted(pty);

    pty.send('hello\n');

    expect(await printed, contains('heard: hello'));
    expect(await pty.ended, 0);
  });

  test('closing it ends the far end rather than leaving it running', () async {
    final pty = Pty.start('sh', <String>['-c', 'sleep 30']);
    unawaited(whatItPrinted(pty));

    await pty.close();

    // SIGHUP is what a terminal window closing sends, and 128 + 1 is how a signal reads as an
    // exit code. Anything else here would mean a session left behind on the machine.
    expect(await pty.ended.timeout(const Duration(seconds: 5)), 129);
  });
}
