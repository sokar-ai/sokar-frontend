import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I press the down arrow
Future<void> iPressTheDownArrow(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pumpAndSettle();
}
