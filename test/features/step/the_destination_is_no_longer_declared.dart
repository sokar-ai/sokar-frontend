import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the destination {'weather'} is no longer declared
Future<void> theDestinationIsNoLongerDeclared(WidgetTester tester, String name) async {
  // Removed at the machine while the dialog is open; the choice made is asked about again.
  World.backend.destinationsHere.removeWhere((each) => each.name == name);
  await World.starting.askAgain();
  await World.settle(tester);
}
