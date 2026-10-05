import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project's own repository {'checkout'} is not listed
Future<void> theProjectsOwnRepositoryIsNotListed(WidgetTester tester, String repository) async {
  expect(find.byKey(Key('repository-$repository')), findsNothing);
}
