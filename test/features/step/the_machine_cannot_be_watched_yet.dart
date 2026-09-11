import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the machine cannot be watched yet
Future<void> theMachineCannotBeWatchedYet(WidgetTester tester) async {
  // The dialog stays open with the button off, rather than closing on a name that would be dropped.
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(tester.widget<FilledButton>(find.byKey(const Key('watch-it'))).onPressed, isNull);
}
