import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the command finder names {'Refresh from the backend'}
Future<void> theCommandFinderNames(WidgetTester tester, String command) async {
  // Scrolled to rather than assumed on screen: the finder lists every action in the product, so
  // the list is long by design and gets longer with every requirement.
  final entry = find.widgetWithText(ListTile, command);
  await tester.scrollUntilVisible(
    entry,
    60,
    scrollable: find.descendant(
      of: find.byKey(const Key('command-list')),
      matching: find.byType(Scrollable),
    ),
  );
  expect(entry, findsOneWidget);
}
