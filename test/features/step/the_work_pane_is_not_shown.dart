import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the work pane is not shown
Future<void> theWorkPaneIsNotShown(WidgetTester tester) async {
  expect(find.byKey(const Key('machine-area')), findsNothing);
}
