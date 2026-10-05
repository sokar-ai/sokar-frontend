import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I start asking what it can install
Future<void> iStartAskingWhatItCanInstall(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('list-packages')));
  await tester.tap(find.byKey(const Key('list-packages')));
  // Frames only: the answer is held, so settling would wait for it.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
