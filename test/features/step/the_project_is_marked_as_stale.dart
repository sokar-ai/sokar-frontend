import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'billing'} is marked as stale
Future<void> theProjectIsMarkedAsStale(WidgetTester tester, String project) async {
  expect(
    find.descendant(
      of: find.ancestor(of: find.text(project), matching: find.byType(Row)).first,
      matching: find.byKey(const Key('project-stale')),
    ),
    findsOneWidget,
  );
}
