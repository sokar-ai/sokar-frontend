import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it is refused before anything is sent
Future<void> itIsRefusedBeforeAnythingIsSent(WidgetTester tester) async {
  final field = tester.widget<TextField>(find.byKey(const Key('connection-private-key')));
  expect(field.decoration!.errorText, contains('public half'));
  expect(field.controller!.text, isEmpty, reason: 'what was refused is kept in the field');
  // Still where the value is given: the machine was never asked.
  expect(find.byKey(const Key('connection-check-says')), findsNothing);
  expect(find.byKey(const Key('connection-check-failed')), findsNothing);
}
