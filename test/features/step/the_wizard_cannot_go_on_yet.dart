import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the wizard cannot go on yet
Future<void> theWizardCannotGoOnYet(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('wizard-next'))).onPressed, isNull);
}
