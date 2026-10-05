import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the terminal says {'The first sign-in builds'}
Future<void> theTerminalSays(WidgetTester tester, String words) async {
  expect(tester.widget<Text>(find.byKey(const Key('unlock-working'))).data, contains(words));
}
