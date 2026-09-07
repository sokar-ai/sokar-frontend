import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'i_open_the_command_finder.dart';

/// Usage: I choose the command {'Refresh from the backend'}
Future<void> iChooseTheCommand(WidgetTester tester, String command) async {
  await iOpenTheCommandFinder(tester);
  // Typing first is how a finder is used, and it keeps the wanted entry on screen whatever the
  // list grows to.
  await tester.enterText(find.byType(TextField), command);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, command));
  await tester.pumpAndSettle();
}
