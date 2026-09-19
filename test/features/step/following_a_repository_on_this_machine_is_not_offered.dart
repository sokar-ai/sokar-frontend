import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: following a repository on this machine is not offered
Future<void> followingARepositoryOnThisMachineIsNotOffered(WidgetTester tester) async {
  final entry = find.descendant(of: find.byKey(const Key('follow-a-repository')), matching: find.byType(ListTile));
  expect(tester.widget<ListTile>(entry).enabled, isFalse);
}
