import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the first step {'machine'} is done {true}
///
/// One of the first start's steps on the work page: `machine`, `project` or `work`.
Future<void> theFirstStepIsDone(WidgetTester tester, String step, bool done) async {
  final card = find.byKey(ValueKey<String>('first-step $step'));
  expect(card, findsOneWidget, reason: 'the first start does not show the step $step');
  expect(find.descendant(of: card, matching: find.byIcon(Icons.check)).evaluate().isNotEmpty, done);
}
