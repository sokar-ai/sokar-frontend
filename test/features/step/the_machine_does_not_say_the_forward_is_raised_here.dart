import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine {'elsewhere'} does not say the forward is raised here
Future<void> theMachineDoesNotSayTheForwardIsRaisedHere(
    WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  expect(find.textContaining('$name  ·  forward raised here'), findsNothing);
  expect(find.text(name), findsWidgets);
}
