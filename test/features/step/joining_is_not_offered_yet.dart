import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: joining is not offered yet
Future<void> joiningIsNotOfferedYet(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('join-it'))).onPressed, isNull);
}
