import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the cost warning says {'the gate now rests on the container holding no credential'}
///
/// Named for what it asserts, not for how it reads: `it warns` was too general and a second
/// feature reused the wording for something else entirely, which then looked for the wrong widget.
/// **Step wording is an API**: two features sharing words must mean the same thing by them.
Future<void> theCostWarningSays(WidgetTester tester, String words) async {
  final said = tester.widget<Text>(find.byKey(const Key('egress-cost')));
  expect(said.data, contains(words));
}
