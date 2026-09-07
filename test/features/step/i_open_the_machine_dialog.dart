import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the machine dialog
Future<void> iOpenTheMachineDialog(WidgetTester tester) async {
  // Opened and nothing chosen. The step that picks "already forwarded" is a different one on
  // purpose: this is the scenario about *not* having chosen.
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  await tester.tap(find.widgetWithText(MenuItemButton, 'Watch another machine…'));
  await World.settle(tester);
}
