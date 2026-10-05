import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: {'github.com'} is not marked as added by the repository
Future<void> isNotMarkedAsAddedByTheRepository(WidgetTester tester, String host) async {
  expect(find.text(host), findsWidgets, reason: '$host should be listed at all');
  expect(find.byKey(ValueKey<String>('added $host')), findsNothing);
}
