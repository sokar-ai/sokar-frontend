import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the work pane is shown
Future<void> theWorkPaneIsShown(WidgetTester tester) async {
  expect(find.byKey(const Key('work-page')), findsOneWidget);
}
