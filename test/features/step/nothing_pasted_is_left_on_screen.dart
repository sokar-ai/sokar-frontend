import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: nothing pasted is left on screen
Future<void> nothingPastedIsLeftOnScreen(WidgetTester tester) async {
  // Once sent, what was pasted is gone from the field — and with the value stored, the field too.
  expect(find.textContaining('BEGIN OPENSSH PRIVATE KEY'), findsNothing);
  for (final field in tester.widgetList<TextField>(find.byKey(const Key('store-paste')))) {
    expect(field.controller?.text, isEmpty);
  }
}
