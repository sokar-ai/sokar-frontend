import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I ask to stop everything on every machine
Future<void> iAskToStopEverythingOnEveryMachine(WidgetTester tester) async {
  // At the foot of the rail, on every screen: nobody in that minute goes looking through menus.
  await tester.tap(find.byKey(const Key('stop-everywhere')));
  await World.settle(tester);
}
