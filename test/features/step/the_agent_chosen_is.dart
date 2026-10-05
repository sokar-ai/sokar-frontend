import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the agent chosen is {'claude'}
Future<void> theAgentChosenIs(WidgetTester tester, String agent) async {
  expect(tester.widget<DropdownButtonFormField<String>>(find.byKey(const Key('start-agent'))).initialValue, agent);
}
