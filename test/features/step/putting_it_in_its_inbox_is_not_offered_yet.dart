import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: putting it in its inbox is not offered yet
Future<void> puttingItInItsInboxIsNotOfferedYet(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('words-confirm'))).onPressed, isNull);
}
