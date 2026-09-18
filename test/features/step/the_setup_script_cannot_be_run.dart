import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the setup script cannot be run
Future<void> theSetupScriptCannotBeRun(WidgetTester tester) async {
  expect(find.byKey(const Key('run-setup')), findsNothing);
}
