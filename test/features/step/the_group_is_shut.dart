import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the group {'stopped'} is shut {true}
///
/// Its heading is shown, and none of its tiles.
Future<void> theGroupIsShut(WidgetTester tester, String group, bool shut) async {
  expect(find.byKey(ValueKey<String>('work-group $group')), findsOneWidget);
  final heading = find.byKey(ValueKey<String>('work-group-fold $group'));
  expect(find.descendant(of: heading, matching: find.byIcon(Icons.chevron_right)).evaluate().isNotEmpty, shut);
}
