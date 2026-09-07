import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I close the detail
Future<void> iCloseTheDetail(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}
