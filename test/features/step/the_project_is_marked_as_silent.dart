import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'checkout'} is marked as silent
Future<void> theProjectIsMarkedAsSilent(WidgetTester tester, String project) async {
  // A switch whose state cannot be seen is one people turn off twice and never back on.
  final row = find.ancestor(of: find.text(project), matching: find.byType(Row));
  expect(
    find.descendant(
      of: row.first,
      matching: find.byIcon(Icons.notifications_off_outlined),
    ),
    findsOneWidget,
  );
}
