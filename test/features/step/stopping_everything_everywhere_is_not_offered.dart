import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: stopping everything everywhere is not offered
Future<void> stoppingEverythingEverywhereIsNotOffered(WidgetTester tester) async {
  expect(tester.widget<TextButton>(find.byKey(const Key('stop-everywhere'))).onPressed, isNull);
}
