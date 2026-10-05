import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the message cannot be decided here
Future<void> theMessageCannotBeDecidedHere(WidgetTester tester) async {
  expect(find.byKey(const Key('release-message')), findsNothing);
  expect(find.byKey(const Key('refuse-message')), findsNothing);
}
