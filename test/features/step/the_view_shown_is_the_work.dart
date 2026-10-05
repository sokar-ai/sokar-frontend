import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the view shown is the work
Future<void> theViewShownIsTheWork(WidgetTester tester) async {
  expect(find.byKey(const Key('work-page')), findsOneWidget);
}
