import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: no work is shown on this page
Future<void> noWorkIsShownOnThisPage(WidgetTester tester) async {
  expect(find.byWidgetPredicate((widget) => widget is Card && '${widget.key}'.contains("'tile ")), findsNothing);
  expect(find.byKey(const Key('its-work')), findsOneWidget);
}
