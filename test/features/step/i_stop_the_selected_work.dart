import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I stop the selected work
Future<void> iStopTheSelectedWork(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Stop it and remove it');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(ListTile, 'Stop it and remove it'));
  await World.settle(tester);

  // Through the confirmation, deliberately: removing work is not something that happens because
  // one entry was chosen from a list.
  await tester.tap(find.widgetWithText(FilledButton, 'Stop and remove'));
  await World.settle(tester);
}
