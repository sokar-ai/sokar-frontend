import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the machine dialog
Future<void> iOpenTheMachineDialog(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(SubmenuButton, 'Machines'));
  await World.settle(tester);
  await tester.tap(find.widgetWithText(MenuItemButton, 'Watch another machine…'));
  await World.settle(tester);
}
