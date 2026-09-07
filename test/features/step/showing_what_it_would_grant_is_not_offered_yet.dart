import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: showing what it would grant is not offered yet
Future<void> showingWhatItWouldGrantIsNotOfferedYet(WidgetTester tester) async {
  // The daemon refuses a call with no scope rather than picking one, and the screen holds the
  // same line: with names typed and no scope chosen there is nothing to press.
  final button = tester.widget<FilledButton>(find.byKey(const Key('widen-preview')));
  expect(button.onPressed, isNull);
}
