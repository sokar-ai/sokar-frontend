import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it lists the unusable agent {'broken-agent'}
Future<void> itListsTheUnusableAgent(WidgetTester tester, String agent) async {
  // Installed and unable to say what it is. Left out, it would read as not installed — the state
  // nobody goes looking for.
  expect(find.byKey(const Key('agent-failure')), findsWidgets);
  expect(find.text(agent), findsOneWidget);
}
