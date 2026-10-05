import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: logging in is not offered
Future<void> loggingInIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('log-in-with-the-agent')), findsNothing);
}
