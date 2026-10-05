import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: following a repository by hand is open
Future<void> followingARepositoryByHandIsOpen(WidgetTester tester) async {
  expect(find.byKey(const Key('forge-form-dialog')), findsNothing);
  expect(find.text('Follow a project'), findsWidgets);
}
