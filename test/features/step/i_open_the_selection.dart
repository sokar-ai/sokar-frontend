import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I open the selection
Future<void> iOpenTheSelection(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}
