import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the connection {'ssh://github.com'} is not marked not protected
Future<void> theConnectionIsNotMarkedNotProtected(WidgetTester tester, String match) async {
  expect(find.byKey(ValueKey<String>('connection $match')), findsOneWidget);
  expect(find.byKey(ValueKey<String>('not-protected $match')), findsNothing);
}
