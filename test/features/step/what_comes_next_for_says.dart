import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: what comes next for {'acme/api'} says {'Make it a project first'}
Future<void> whatComesNextForSays(WidgetTester tester, String repository, String words) async {
  expect(tester.widget<Text>(find.byKey(ValueKey<String>('repository-says $repository'))).data, contains(words));
}
