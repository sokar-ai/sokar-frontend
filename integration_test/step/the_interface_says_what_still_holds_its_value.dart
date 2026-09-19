import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the interface says what still holds its value
Future<void> theInterfaceSaysWhatStillHoldsItsValue(WidgetTester tester) async {
  final said = tester.widget<Text>(find.byKey(const Key('connections-forgotten'))).data ?? '';
  // The machine's own sentence about it, never one composed here.
  expect(said, startsWith('Forgotten.'));
}
