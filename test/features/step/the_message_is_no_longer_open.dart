import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the message is no longer open
Future<void> theMessageIsNoLongerOpen(WidgetTester tester) async {
  expect(find.byKey(const Key('held-message-dialog')), findsNothing);
}
