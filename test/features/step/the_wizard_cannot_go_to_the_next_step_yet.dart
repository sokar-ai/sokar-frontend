import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the wizard cannot go to the next step yet
Future<void> theWizardCannotGoToTheNextStepYet(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('setup-next'))).onPressed, isNull);
}
