import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the start tile says {'Start work'}
Future<void> theStartTileSays(WidgetTester tester, String words) async {
  expect(tester.widget<Text>(find.byKey(const Key('start-work-says'))).data, contains(words));
}
