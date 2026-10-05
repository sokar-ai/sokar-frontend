import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the session is on screen
Future<void> theSessionIsOnScreen(WidgetTester tester) async {
  expect(find.byKey(const Key('terminal')), findsOneWidget);
}
