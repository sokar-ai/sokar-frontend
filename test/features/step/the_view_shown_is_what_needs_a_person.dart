import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the view shown is what needs a person
Future<void> theViewShownIsWhatNeedsAPerson(WidgetTester tester) async {
  expect(find.byKey(const Key('needing-count')), findsOneWidget);
}
