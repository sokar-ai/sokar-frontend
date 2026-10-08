import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the file is read and sent
Future<void> theFileIsReadAndSent(WidgetTester tester) async {
  // Reading a file is real input and output, which the widget test's clock does not carry: each
  // round lets the reading go on outside it, and a frame then delivers what it read. It ends when
  // the status line says how it went, and fails rather than waiting on a hand-in that never ends.
  String said() => tester.widget<Text>(find.byKey(const Key('status-line'))).data ?? '';
  final before = said();
  for (var round = 0; round < 2000; round++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1)));
    await tester.pump();
    if (said() != before) {
      await World.settle(tester);
      return;
    }
  }
  fail('the status line never said how the hand-in went; it still says "$before"');
}
