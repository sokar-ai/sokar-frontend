import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the unlock terminal ends and is put away
Future<void> theUnlockTerminalEndsAndIsPutAway(WidgetTester tester) async {
  askedBeforeItWasPutAway = World.backend.storeAsked.where((each) => each == 'credentials').length;
  World.terminals.last.endsWith(0);
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('unlock-done')));
  await World.settle(tester);
}

/// How often the store had been asked about when the terminal was put away.
int askedBeforeItWasPutAway = 0;
