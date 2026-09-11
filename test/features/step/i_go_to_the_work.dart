import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I go to the work
Future<void> iGoToTheWork(WidgetTester tester) async {
  // The window opens on what needs a person; the work is on the machine's own entry.
  await tapOnScreen(tester, railEntryFor(World.machines.current.name));
  await World.settle(tester);
}
