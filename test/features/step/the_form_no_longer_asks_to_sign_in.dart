import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the form no longer asks to sign in
Future<void> theFormNoLongerAsksToSignIn(WidgetTester tester) async {
  expect(find.byKey(const Key('start-sign-in')), findsNothing);
  expect(find.byKey(const Key('start-go')), findsOneWidget);
}
