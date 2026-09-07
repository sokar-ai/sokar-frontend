import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it says what it would do
Future<void> itSaysWhatItWouldDo(WidgetTester tester) async {
  final said = tester.widget<Text>(find.byKey(const Key('what-it-would-do')));
  expect(said.data, 'This is what it would do');
}
