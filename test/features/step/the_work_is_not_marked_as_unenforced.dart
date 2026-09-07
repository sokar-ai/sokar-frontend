import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the work {'sokar-billing-shell'} is not marked as unenforced
Future<void> theWorkIsNotMarkedAsUnenforced(
    WidgetTester tester, String work) async {
  final row = find.ancestor(of: find.text(work), matching: find.byType(Row));
  expect(
    find.descendant(of: row.first, matching: find.byKey(const Key('unenforced'))),
    findsNothing,
  );
}
