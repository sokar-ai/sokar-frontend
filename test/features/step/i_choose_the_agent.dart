import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the agent {'An Agent'}
Future<void> iChooseTheAgent(WidgetTester tester, String agent) async {
  await tester.tap(find.byKey(const Key('start-agent')));
  await World.settle(tester);
  // Matched loosely and taken last: an agent is listed with its version beside it when it
  // reports one, and the menu draws the chosen item over the button, so the words are on screen
  // twice once something is selected.
  await tester.tap(find.textContaining(agent).last);
  await World.settle(tester);
}
