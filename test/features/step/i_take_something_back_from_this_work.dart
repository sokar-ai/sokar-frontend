import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I take something back from this work
Future<void> iTakeSomethingBackFromThisWork(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Take something back from this work');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(ListTile, 'Take something back from this work'));
  await World.settle(tester);
}
