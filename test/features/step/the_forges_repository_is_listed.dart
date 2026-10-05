import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the forge's repository {'acme/web'} is listed
Future<void> theForgesRepositoryIsListed(WidgetTester tester, String name) async {
  expect(find.byKey(ValueKey<String>('repository $name')), findsOneWidget);
}
