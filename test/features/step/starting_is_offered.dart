import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: starting is offered
Future<void> startingIsOffered(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('start-go'))).onPressed, isNotNull);
}
