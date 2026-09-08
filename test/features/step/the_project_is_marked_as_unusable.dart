import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'unrecorded'} is marked as unusable
Future<void> theProjectIsMarkedAsUnusable(WidgetTester tester, String project) async {
  final row = find.ancestor(of: find.text(project), matching: find.byType(Row)).first;
  expect(
    find.descendant(of: row, matching: find.byIcon(Icons.link_off)),
    findsOneWidget,
    reason: 'nothing can act on it, and the row has to say so',
  );
}
