import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I ask to stop Sokar on this machine
Future<void> iAskToStopSokarOnThisMachine(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Stop Sokar on this machine');
  await World.settle(tester);
  await tester.tap(inTheFinder('Stop Sokar on this machine'));
  await World.settle(tester);
  await followTheFinder(tester);
}
