import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: creating it is not offered
Future<void> creatingItIsNotOffered(WidgetTester tester) async {
  expect(
    tester.widget<FilledButton>(find.byKey(const Key('create-the-project'))).onPressed,
    isNull,
  );
}
