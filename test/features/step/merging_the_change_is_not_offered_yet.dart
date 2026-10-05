import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: merging the change {'plan'} is not offered yet
Future<void> mergingTheChangeIsNotOfferedYet(WidgetTester tester, String name) async {
  expect(tester.widget<TextButton>(find.byKey(ValueKey<String>('merge-change $name'))).onPressed, isNull);
}
