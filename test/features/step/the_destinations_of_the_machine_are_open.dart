import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the destinations of the machine are open
Future<void> theDestinationsOfTheMachineAreOpen(WidgetTester tester) async {
  expect(find.byKey(const Key('destinations-dialog')), findsOneWidget);
}
