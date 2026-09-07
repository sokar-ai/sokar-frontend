import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it says a newer build is installed
Future<void> itSaysANewerBuildIsInstalled(WidgetTester tester) async {
  expect(find.byKey(const Key('newer-version')), findsOneWidget);
}
