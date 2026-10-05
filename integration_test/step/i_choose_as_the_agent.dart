import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';
import '../support/new_person.dart';

/// Usage: I choose {'Claude'} as the agent
Future<void> iChooseAsTheAgent(WidgetTester tester, String agent) async {
  if (!walkingAsANewPerson) return;
  final field = find.byKey(const Key('start-agent'));
  expect(field, findsOneWidget, reason: 'no agent is installed');
  await tester.ensureVisible(field);
  await tester.tap(field);
  await pumpFor(tester);
  await tester.tap(find.textContaining(agent).last);
  await pumpFor(tester, const Duration(seconds: 5));
  noteTheWindow(tester, 'starting work, $agent chosen');
}
