import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the rail says {'1'} is waiting
Future<void> theRailSaysIsWaiting(WidgetTester tester, String count) async {
  // On the rail, not inside the section: a question with a deadline cannot be something you find
  // only by having gone to look in the right place.
  expect(
    find.descendant(
      of: find.byKey(const Key('waiting-count')),
      matching: find.text(count),
    ),
    findsOneWidget,
  );
}
