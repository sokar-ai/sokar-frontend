import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the private key field is empty
Future<void> thePrivateKeyFieldIsEmpty(WidgetTester tester) async {
  final field = tester.widget<TextField>(find.byKey(const Key('connection-private-key')));
  expect(field.controller!.text, isEmpty);
  // The key's own first line, not the words of a refusal that describes one.
  expect(find.textContaining('-----BEGIN OPENSSH'), findsNothing);
}
