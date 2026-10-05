import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the count of what needs a person is {'1 need you'}
Future<void> theCountOfWhatNeedsAPersonIs(WidgetTester tester, String count) async {
  expect(tester.widget<Text>(find.byKey(const Key('needing-count'))).data, count);
}
