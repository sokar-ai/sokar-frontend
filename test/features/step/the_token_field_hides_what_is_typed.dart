import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the token field hides what is typed
Future<void> theTokenFieldHidesWhatIsTyped(WidgetTester tester) async {
  final field = tester.widget<TextField>(find.byKey(const Key('forge-token')));
  expect(field.obscureText, isTrue);
  expect(field.enableSuggestions, isFalse);
}
