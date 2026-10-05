import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the change {'plan'} is still listed
Future<void> theChangeIsStillListed(WidgetTester tester, String name) async {
  expect(find.byKey(ValueKey<String>('change $name')), findsOneWidget);
}
