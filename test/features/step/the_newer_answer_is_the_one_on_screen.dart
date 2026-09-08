import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the newer answer is the one on screen
Future<void> theNewerAnswerIsTheOneOnScreen(WidgetTester tester) async {
  // A stale answer landing on top of a newer one is the failure this criterion names, and it is
  // invisible: both look like an answer.
  expect(find.text('the-newer-answer'), findsOneWidget);
  expect(find.text('a-provider'), findsNothing);
  expect(find.byKey(const Key('credential-name')), findsOneWidget);
}
