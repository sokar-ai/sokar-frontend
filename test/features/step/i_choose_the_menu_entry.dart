import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the menu entry {'Appearance: dark'}
Future<void> iChooseTheMenuEntry(WidgetTester tester, String entry) async {
  // A pointer alone, deliberately: no shortcut, no finder. An action only the keyboard can reach
  // is an action half the people using this cannot reach at all.
  await tester.tap(find.widgetWithText(MenuItemButton, entry));
  await World.settle(tester);
}
