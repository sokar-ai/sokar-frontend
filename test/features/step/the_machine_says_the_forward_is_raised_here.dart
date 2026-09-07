import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine {'the build machine'} says the forward is raised here
Future<void> theMachineSaysTheForwardIsRaisedHere(
    WidgetTester tester, String name) async {
  // Which of the two kinds a machine is decides what happens when it stops answering and what
  // happens when the window closes, so it is said rather than left to be inferred.
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  expect(find.textContaining('$name  ·  forward raised here'), findsOneWidget);
}
