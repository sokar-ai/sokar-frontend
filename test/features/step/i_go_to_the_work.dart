import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I go to the work
Future<void> iGoToTheWork(WidgetTester tester) async {
  await toTheMachines(tester);
  // The machine's own page, from the list of machines: its title, its menu and its vault.
  await tapOnScreen(tester, railEntryFor(World.machines.current.name));
  await World.settle(tester);
}
