import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I add the set {'Container registries'}
Future<void> iAddTheSet(WidgetTester tester, String label) async {
  final row = find.ancestor(of: find.text(label), matching: find.byType(ListTile));
  await tester.tap(find.descendant(
      of: row.first, matching: find.widgetWithText(FilledButton, 'Add')));
  await World.settle(tester);
}
