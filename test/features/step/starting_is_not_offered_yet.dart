import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: starting is not offered yet
Future<void> startingIsNotOfferedYet(WidgetTester tester) async {
  final button = tester.widget<FilledButton>(find.byKey(const Key('start-go')));
  expect(button.onPressed, isNull);
}
