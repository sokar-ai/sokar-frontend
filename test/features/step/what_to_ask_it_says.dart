import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: what to ask it says {'Fix the rounding in Money.pennies'}
Future<void> whatToAskItSays(WidgetTester tester, String words) async {
  final box = tester.widget<TextField>(find.byKey(const Key('start-prompt')));
  expect(box.controller?.text, contains(words));
}
