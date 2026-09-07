import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the work {'sokar-checkout-shell'} is still selected
Future<void> theWorkIsStillSelected(WidgetTester tester, String work) async {
  expect(
    find.ancestor(
      of: find.text(work),
      matching: find.byKey(const Key('selected-row')),
    ),
    findsOneWidget,
  );
}
