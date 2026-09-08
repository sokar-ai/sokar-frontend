import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'checkout'} is not marked as stale
Future<void> theProjectIsNotMarkedAsStale(WidgetTester tester, String project) async {
  expect(
    find.descendant(
      of: find.ancestor(of: find.text(project), matching: find.byType(Row)).first,
      matching: find.byKey(const Key('project-stale')),
    ),
    findsNothing,
  );
}
