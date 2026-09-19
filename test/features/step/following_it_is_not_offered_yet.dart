import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: following it is not offered yet
Future<void> followingItIsNotOfferedYet(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('follow-it'))).onPressed, isNull);
}
