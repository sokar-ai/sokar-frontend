import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the machine {'elsewhere'} is shown as the same node as {'this machine'}
///
/// Read off the entry's own line rather than off the menu, so it is the machine in question that
/// is marked and not merely the words appearing somewhere on screen.
Future<void> theMachineIsShownAsTheSameNodeAs(
    WidgetTester tester, String name, String other) async {
  final lines = tester
      .widgetList<Text>(find.byType(Text))
      .map((each) => each.data ?? '')
      .where((words) => words.startsWith(name));

  expect(lines, isNotEmpty, reason: '$name is not in the machine list at all');
  expect(lines.any((words) => words.contains('the same node as $other')), isTrue,
      reason: '$name does not say it is the same node as $other: $lines');
}
