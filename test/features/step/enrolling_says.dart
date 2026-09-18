import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: enrolling says {'This device cannot open the store yet. Enroll it so it can.'}
Future<void> enrollingSays(WidgetTester tester, String words) async {
  final button = find.byKey(const Key('vault-enroll'));
  expect(button, findsOneWidget, reason: 'enrolling is not offered');
  expect(find.ancestor(of: button, matching: find.byTooltip(words)), findsOneWidget,
      reason: 'enrolling says something else');
}
