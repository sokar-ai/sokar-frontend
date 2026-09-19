import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I add the set {'Container registries'}
Future<void> iAddTheSet(WidgetTester tester, String label) async {
  // A lazy list builds only what is on screen: bring the set into view before looking for it.
  await tester.scrollUntilVisible(find.text(label), 200, scrollable: find.byType(Scrollable).last);
  final row = find.ancestor(of: find.text(label), matching: find.byType(ListTile));
  await tester.tap(find.descendant(
      of: row.first, matching: find.widgetWithText(FilledButton, 'Add')));
  await World.settle(tester);
}
