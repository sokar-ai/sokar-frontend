import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the repository {'payments-api'} is chosen
Future<void> theRepositoryIsChosen(WidgetTester tester, String repository) async {
  final group = tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
  expect(group.groupValue, repository);
}
