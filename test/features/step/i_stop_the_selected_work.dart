import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I stop the selected work
Future<void> iStopTheSelectedWork(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Stop it, keeping its workspace');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(ListTile, 'Stop it, keeping its workspace'));
  await World.settle(tester);
}
