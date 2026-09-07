import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'checkout'} is selected
Future<void> theProjectIsSelected(WidgetTester tester, String project) async {
  expect(
    find.ancestor(
      of: find.text(project),
      matching: find.byKey(const Key('selected-row')),
    ),
    findsOneWidget,
  );
}
