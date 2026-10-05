import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: binding the machine is not offered
Future<void> bindingTheMachineIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('binding-dialog')), findsNothing);
}
