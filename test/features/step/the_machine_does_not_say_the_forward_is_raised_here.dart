import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: the machine {'the build machine'} does not say the forward is raised here
Future<void> theMachineDoesNotSayTheForwardIsRaisedHere(WidgetTester tester, String name) async {
  // Which kind a machine is decides what happens when it stops answering and when the window
  // closes, so its title says it rather than leaving it to be inferred.
  await tapOnScreen(tester, railEntryFor(name));
  await World.settle(tester);
  expect(
    find.descendant(
        of: find.byKey(const Key('machine-kind')),
        matching: find.textContaining('forward raised here'),
        matchRoot: true),
    findsNothing,
  );
}
