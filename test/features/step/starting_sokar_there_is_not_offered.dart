import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: starting Sokar there is not offered
Future<void> startingSokarThereIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('offer-to-start')), findsNothing);
}
