import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the connection {'https://gitlab.example/acme/'} is marked not protected
Future<void> theConnectionIsMarkedNotProtected(WidgetTester tester, String match) async {
  expect(find.byKey(ValueKey<String>('not-protected $match')), findsOneWidget);
}
