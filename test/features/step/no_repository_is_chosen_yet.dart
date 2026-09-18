import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: no repository is chosen yet
Future<void> noRepositoryIsChosenYet(WidgetTester tester) async {
  expect(find.byKey(const Key('start-repository-checkout')), findsOneWidget);
  final group = tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
  expect(group.groupValue, isNull, reason: 'a repository was chosen for the person');
}
