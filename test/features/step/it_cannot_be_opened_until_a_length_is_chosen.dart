import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it cannot be opened until a length is chosen
Future<void> itCannotBeOpenedUntilALengthIsChosen(WidgetTester tester) async {
  final open = tester.widget<FilledButton>(find.byKey(const Key('open-confirm')));
  expect(open.onPressed, isNull, reason: 'a length was chosen for the person');
}
