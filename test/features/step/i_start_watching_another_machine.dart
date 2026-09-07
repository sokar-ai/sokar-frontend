import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start watching another machine
Future<void> iStartWatchingAnotherMachine(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  await tester.tap(find.widgetWithText(MenuItemButton, 'Watch another machine…'));
  await World.settle(tester);
}
