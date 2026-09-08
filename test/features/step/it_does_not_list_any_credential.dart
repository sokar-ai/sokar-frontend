import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it does not list any credential
Future<void> itDoesNotListAnyCredential(WidgetTester tester) async {
  expect(find.byKey(const Key('credential-name')), findsNothing);
}
