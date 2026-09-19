import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: adding it is not offered yet
Future<void> addingItIsNotOfferedYet(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('connection-add'))).onPressed, isNull);
}
