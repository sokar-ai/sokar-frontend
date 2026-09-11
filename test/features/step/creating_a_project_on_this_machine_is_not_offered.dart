import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: creating a project on this machine is not offered
Future<void> creatingAProjectOnThisMachineIsNotOffered(WidgetTester tester) async {
  final entry = find.descendant(of: find.byKey(const Key('new-project')), matching: find.byType(ListTile));
  expect(tester.widget<ListTile>(entry).enabled, isFalse);
}
