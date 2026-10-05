import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the session is not on screen
Future<void> theSessionIsNotOnScreen(WidgetTester tester) async {
  expect(find.byKey(const Key('terminal')), findsNothing);
}
