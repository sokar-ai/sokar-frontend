import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: starting Sokar there is offered
Future<void> startingSokarThereIsOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('offer-to-start')), findsOneWidget);
}
