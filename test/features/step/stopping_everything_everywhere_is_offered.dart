import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: stopping everything everywhere is offered
Future<void> stoppingEverythingEverywhereIsOffered(WidgetTester tester) async {
  expect(tester.widget<TextButton>(find.byKey(const Key('stop-everywhere'))).onPressed, isNotNull);
}
