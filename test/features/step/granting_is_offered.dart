import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: granting {'jira'} is offered
Future<void> grantingIsOffered(WidgetTester tester, String name) async {
  expect(find.byKey(ValueKey<String>('grant $name')), findsOneWidget);
}
