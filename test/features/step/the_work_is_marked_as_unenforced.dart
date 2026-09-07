import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'the_work_is_shown_as.dart';

/// Usage: the work {'sokar-billing-audit'} is marked as unenforced
Future<void> theWorkIsMarkedAsUnenforced(WidgetTester tester, String work) async {
  // Wherever the work appears, not only where somebody went looking: nothing will ever be asked
  // about what this run reaches, and that was a choice.
  final row = find.ancestor(of: find.text(work), matching: find.byType(Row));
  expect(
    find.descendant(of: row.first, matching: find.byKey(const Key('unenforced'))),
    findsOneWidget,
    reason: '$work should be marked: ${whatItSaysAbout(tester, work)}',
  );
}
