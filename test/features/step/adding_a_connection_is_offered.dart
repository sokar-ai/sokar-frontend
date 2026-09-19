import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: adding a connection is offered
Future<void> addingAConnectionIsOffered(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('add-connection'))).onPressed, isNotNull);
}
