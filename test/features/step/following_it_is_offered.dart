import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: following it is offered
Future<void> followingItIsOffered(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('follow-it'))).onPressed, isNotNull);
}
