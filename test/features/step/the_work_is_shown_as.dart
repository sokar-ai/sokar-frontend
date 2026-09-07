import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/ui/panes.dart';

/// Everything the work list says about one task.
String whatItSaysAbout(WidgetTester tester, String work) {
  final row = find.ancestor(of: find.text(work), matching: find.byType(Row));
  return tester
      .widgetList<Text>(find.descendant(of: row.first, matching: find.byType(Text)))
      .map((each) => each.data ?? '')
      .join(' ');
}

/// Usage: the work {'sokar-checkout-shell'} is shown as {'waiting'}
Future<void> theWorkIsShownAs(
    WidgetTester tester, String work, String words) async {
  expect(find.byType(WorkPane), findsOneWidget);
  expect(whatItSaysAbout(tester, work), contains(words));
}
