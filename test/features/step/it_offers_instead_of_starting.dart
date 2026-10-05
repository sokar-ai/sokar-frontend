import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it offers {'Sign in first'} instead of starting
Future<void> itOffersInsteadOfStarting(WidgetTester tester, String label) async {
  expect(find.byKey(const Key('start-go')), findsNothing);
  expect(find.widgetWithText(FilledButton, label), findsOneWidget);
}
