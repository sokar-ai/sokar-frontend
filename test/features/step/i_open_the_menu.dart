import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the menu {'View'}
Future<void> iOpenTheMenu(WidgetTester tester, String menu) async {
  await tester.tap(find.widgetWithText(SubmenuButton, menu));
  await World.settle(tester);
}
