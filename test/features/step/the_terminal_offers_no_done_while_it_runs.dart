import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the terminal offers no Done while it runs
Future<void> theTerminalOffersNoDoneWhileItRuns(WidgetTester tester) async {
  expect(find.byKey(const Key('unlock-done')), findsNothing);
  expect(find.widgetWithText(TextButton, 'Cancel the sign-in'), findsOneWidget);
}
