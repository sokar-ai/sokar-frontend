import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: only Cancel is offered
Future<void> onlyCancelIsOffered(WidgetTester tester) async {
  expect(tester.widget<TextButton>(find.byKey(const Key('wizard-back'))).onPressed, isNull);
  expect(tester.widget<FilledButton>(find.byKey(const Key('setup-next'))).onPressed, isNull);
  expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel')).onPressed, isNotNull);
}
