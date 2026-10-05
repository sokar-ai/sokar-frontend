import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the forwarding asks {'Forward it to its origin'}
Future<void> theForwardingAsks(WidgetTester tester, String title) async {
  expect(find.descendant(of: find.byType(AlertDialog), matching: find.text(title)), findsOneWidget);
}
