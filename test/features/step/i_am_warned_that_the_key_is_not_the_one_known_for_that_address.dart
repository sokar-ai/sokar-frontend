import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I am warned that the key is not the one known for that address
Future<void> iAmWarnedThatTheKeyIsNotTheOneKnownForThatAddress(WidgetTester tester) async {
  expect(find.byKey(const Key('host-key-changed')), findsOneWidget);
  expect(find.text('Replace the old key'), findsOneWidget);
}
