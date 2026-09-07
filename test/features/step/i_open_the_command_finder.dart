import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I open the command finder
Future<void> iOpenTheCommandFinder(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}
