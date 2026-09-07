import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_open_the_command_finder.dart';

/// Usage: I read the log {'agent.log'}
Future<void> iReadTheLog(WidgetTester tester, String log) async {
  await iOpenTheCommandFinder(tester);
  await tester.enterText(find.byType(TextField), 'Read one of its logs');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(ListTile, 'Read one of its logs'));
  await World.settle(tester);

  // Typed, because nothing lists a task's logs. The dialog says so rather than leaving it to be
  // discovered by naming one that is not there.
  await tester.enterText(find.byType(TextField), log);
  await World.settle(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Read it'));
  await World.settle(tester);
}
