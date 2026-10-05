import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: granting {'a-provider'} is not offered
Future<void> grantingIsNotOffered(WidgetTester tester, String name) async {
  expect(find.byKey(const Key('credential-name')), findsWidgets);
  expect(find.byKey(ValueKey<String>('grant $name')), findsNothing);
}
