import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: working on it on the machine is not offered
Future<void> workingOnItOnTheMachineIsNotOffered(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('binding-bind'))).onPressed, isNull);
}
