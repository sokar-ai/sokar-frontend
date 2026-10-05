import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it lists the credential {'a-provider'}
Future<void> itListsTheCredential(WidgetTester tester, String name) async {
  expect(find.byKey(const Key('credential-name')), findsWidgets);
  expect(find.text(name), findsOneWidget);
}
