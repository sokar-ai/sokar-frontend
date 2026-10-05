import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: what is held is shown
Future<void> whatIsHeldIsShown(WidgetTester tester) async {
  // Showing what is held is the whole job of a refusal. "It refused" without saying what is at
  // stake leaves the choice about somebody's afternoon to be made blind.
  final held = tester.widget<SelectableText>(find.byKey(const Key('what-is-held')));
  expect(held.data, isNotNull);
  expect(held.data, isNotEmpty);
}
