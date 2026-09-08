import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I describe a new project
Future<void> iDescribeANewProject(WidgetTester tester) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Describe a new project');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(ListTile, 'Describe a new project'));
  await World.settle(tester);
}
