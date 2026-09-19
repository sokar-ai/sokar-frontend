import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the repositories are listed with a line between each
Future<void> theRepositoriesAreListedWithALineBetweenEach(WidgetTester tester) async {
  final list = find.byKey(const Key('project-repositories'));
  expect(list, findsOneWidget, reason: 'the repositories are not one list');
  final rows = find.descendant(of: list, matching: find.byWidgetPredicate(
      (each) => each.key is ValueKey<String> && (each.key! as ValueKey<String>).value.startsWith('repository-')));
  expect(find.descendant(of: list, matching: find.byType(Divider)), findsNWidgets(rows.evaluate().length - 1));
}
