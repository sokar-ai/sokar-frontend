import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the command {'Remove what Sokar built for this project'} is offered
Future<void> theCommandIsOffered(WidgetTester tester, String command) async {
  await tester.enterText(find.byType(TextField), command);
  await World.settle(tester);

  final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, command));
  expect(tile.enabled, isTrue, reason: '$command should be runnable now');
}
