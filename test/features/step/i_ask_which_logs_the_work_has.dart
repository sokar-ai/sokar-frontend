import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I ask which logs the work has
Future<void> iAskWhichLogsTheWorkHas(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Read one of its logs');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(ListTile, 'Read one of its logs'));
  await World.settle(tester);
}
