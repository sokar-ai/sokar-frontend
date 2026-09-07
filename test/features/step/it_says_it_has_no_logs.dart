import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it says it has no logs
Future<void> itSaysItHasNoLogs(WidgetTester tester) async {
  // An empty list is a normal answer, not a failure, and has to read as one.
  expect(find.byKey(const Key('no-logs')), findsOneWidget);
}
