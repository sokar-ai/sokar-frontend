import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: enrolling is not offered
Future<void> enrollingIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('vault-enroll')), findsNothing);
}
