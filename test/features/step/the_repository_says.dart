import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the repository {'payments-api'} says {'4 behind'}
Future<void> theRepositorySays(WidgetTester tester, String repository, String words) async {
  expect(
    find.descendant(of: find.byKey(Key('repository-$repository')), matching: find.textContaining(words)),
    findsOneWidget,
  );
}
