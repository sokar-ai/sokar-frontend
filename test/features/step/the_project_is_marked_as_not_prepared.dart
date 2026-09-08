import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// How many "not prepared" marks are on one project's row.
///
/// Counted on the row rather than on the screen: every project is listed, so a mark found
/// anywhere would pass for a project that has none.
int marksNotPrepared(WidgetTester tester, String project) {
  final row = find.ancestor(of: find.text(project), matching: find.byType(Row)).first;
  return tester
      .widgetList(find.descendant(
        of: row,
        matching: find.byKey(const Key('project-unprepared')),
      ))
      .length;
}

/// Usage: the project {'unrecorded'} is marked as not prepared
Future<void> theProjectIsMarkedAsNotPrepared(WidgetTester tester, String project) async {
  // The one state that makes an otherwise healthy project unusable: nothing starts here until an
  // image is built. Marked on the row rather than discovered by trying.
  expect(marksNotPrepared(tester, project), 1,
      reason: '$project should be marked as not prepared');
}
