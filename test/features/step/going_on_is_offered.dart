import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: going on is offered
Future<void> goingOnIsOffered(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('wizard-next'))).onPressed, isNotNull);
}
