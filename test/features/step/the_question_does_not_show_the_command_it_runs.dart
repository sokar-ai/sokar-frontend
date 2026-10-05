import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the question does not show the command it runs
Future<void> theQuestionDoesNotShowTheCommandItRuns(WidgetTester tester) async {
  expect(find.byKey(const Key('start-command')), findsOneWidget);
  expect(find.byKey(const Key('forwarding-command')), findsNothing);
}
