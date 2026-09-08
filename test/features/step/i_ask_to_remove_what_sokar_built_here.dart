import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I ask to remove what Sokar built here
Future<void> iAskToRemoveWhatSokarBuiltHere(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(
      find.byType(TextField), 'Remove what Sokar built for this project');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(
      ListTile, 'Remove what Sokar built for this project'));
  await World.settle(tester);
}
