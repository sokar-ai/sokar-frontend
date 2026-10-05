import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: nothing is shown below the run yet
Future<void> nothingIsShownBelowTheRunYet(WidgetTester tester) async {
  expect(find.byKey(const Key('setup-output')), findsNothing);
  expect(find.byKey(const Key('asking-output')), findsNothing);
}
