import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: nothing needs me
Future<void> nothingNeedsMe(WidgetTester tester) async {
  expect(tester.widget<Text>(find.byKey(const Key('needing-count'))).data, 'nothing needs you');
}
