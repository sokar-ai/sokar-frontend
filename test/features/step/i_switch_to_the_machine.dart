import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I switch to the machine {'elsewhere'}
Future<void> iSwitchToTheMachine(WidgetTester tester, String name) async {
  await toTheMachines(tester);
  expect(railEntryFor(name), findsOneWidget, reason: '$name is not among the machines');
  await tapOnScreen(tester, railEntryFor(name));
  await World.settle(tester);
}
