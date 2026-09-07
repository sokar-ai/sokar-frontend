import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I switch to the machine {'elsewhere'}
Future<void> iSwitchToTheMachine(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  await tester.tap(find.widgetWithText(MenuItemButton, name));
  await World.settle(tester);
}
