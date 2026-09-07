import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: what to ask it cannot be filled in
Future<void> whatToAskItCannotBeFilledIn(WidgetTester tester) async {
  // The backend would accept a prompt with SHELL and record SHELL — a run nobody is attached to,
  // described as one somebody is driving. So the combination is not offered at all.
  final box = tester.widget<TextField>(find.byKey(const Key('start-prompt')));
  expect(box.enabled, isFalse);
}
