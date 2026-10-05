import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the wizard is at step {'2'}
Future<void> theWizardIsAtStep(WidgetTester tester, String step) async {
  final title = find.descendant(of: find.byKey(const Key('connection-wizard')), matching: find.textContaining('of 3'));
  expect(tester.widget<Text>(title).data, contains('— $step of 3'));
}
