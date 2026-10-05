import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: deleting its key cannot be chosen
Future<void> deletingItsKeyCannotBeChosen(WidgetTester tester) async {
  expect(tester.widget<CheckboxListTile>(find.byKey(const Key('forget-key'))).onChanged, isNull);
}
