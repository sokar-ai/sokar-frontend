import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the trial says nothing
Future<void> theTrialSaysNothing(WidgetTester tester) async {
  expect(find.byKey(const Key('trial-result')), findsNothing);
}
