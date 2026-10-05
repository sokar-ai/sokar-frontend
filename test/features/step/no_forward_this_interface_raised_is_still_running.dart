import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no forward this interface raised is still running
Future<void> noForwardThisInterfaceRaisedIsStillRunning(WidgetTester tester) async {
  // Closing leaves no forward running. What is held is what would still be up tomorrow.
  expect(World.forwardsAsked, isNotEmpty, reason: 'nothing was raised, so nothing was proven');
  expect(World.forwardsHeld, isEmpty);
}
