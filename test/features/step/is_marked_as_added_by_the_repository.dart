import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: {'api.stripe.com'} is marked as added by the repository
Future<void> isMarkedAsAddedByTheRepository(WidgetTester tester, String host) async {
  expect(find.byKey(ValueKey<String>('added $host')), findsOneWidget);
}
