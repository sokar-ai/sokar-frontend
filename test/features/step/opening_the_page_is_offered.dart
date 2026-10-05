import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: opening the page is offered
Future<void> openingThePageIsOffered(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('grant-open'))).onPressed, isNotNull);
}
