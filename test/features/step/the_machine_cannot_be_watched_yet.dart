import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the machine cannot be watched yet
Future<void> theMachineCannotBeWatchedYet(WidgetTester tester) async {
  // The dialog stays open with the button off, rather than closing on a name that would be dropped.
  expect(find.byType(AlertDialog), findsOneWidget);
  // On the wizard's first page that is the button that goes on; on its second, the one that watches.
  final next = find.byKey(const Key('wizard-next'));
  final button = next.evaluate().isEmpty ? find.byKey(const Key('watch-it')) : next;
  expect(tester.widget<FilledButton>(button).onPressed, isNull);
}
