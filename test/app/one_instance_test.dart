import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/one_instance.dart';

/// Two interfaces running is not untidy, it is wrong: each watches every configured machine, so a
/// clearance question is raised twice and answered by whichever window somebody happened to see.
void main() {
  late String path;

  setUp(() {
    path = '/tmp/sokar-one-${DateTime.now().microsecondsSinceEpoch}.sock';
    addTearDown(() {
      final socket = File(path);
      if (socket.existsSync()) socket.deleteSync();
    });
  });

  test('the first launch takes charge', () async {
    final first = await OneInstance.take(comeForward: () {}, at: path);

    expect(first.inCharge, isTrue);
    await first.release();
  });

  test('a second launch joins rather than competing, and asks for the window', () async {
    var asked = 0;
    final first = await OneInstance.take(comeForward: () => asked++, at: path);

    final second = await OneInstance.take(comeForward: () {}, at: path);

    expect(second.inCharge, isFalse, reason: 'two would raise everything twice');
    while (asked == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(asked, 1);
    await first.release();
  });

  test('a socket left by a run that died is taken over, not surrendered to', () async {
    // Otherwise one crash means the interface can never be opened again without somebody knowing
    // to delete a file they have never heard of.
    File(path).writeAsStringSync('');

    final taking = await OneInstance.take(comeForward: () {}, at: path);

    expect(taking.inCharge, isTrue);
    await taking.release();
  });

  test('releasing leaves nothing behind for the next launch to trip over', () async {
    final first = await OneInstance.take(comeForward: () {}, at: path);

    await first.release();

    expect(File(path).existsSync(), isFalse);
  });
}
