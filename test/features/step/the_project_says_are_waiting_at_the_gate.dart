import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'checkout'} says {'2'} are waiting at the gate
Future<void> theProjectSaysAreWaitingAtTheGate(
    WidgetTester tester, String project, String count) async {
  // Waiting for review is the one thing that makes a project need a person, so it is a number on
  // the row rather than something found by opening it.
  final row = find.ancestor(of: find.text(project), matching: find.byType(Row)).first;
  expect(find.descendant(of: row, matching: find.byType(Chip)), findsOneWidget);
  expect(find.descendant(of: row, matching: find.text(count)), findsOneWidget);
}
