import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine takes away the slot of {'laptop'}
Future<void> theMachineTakesAwayTheSlotOf(WidgetTester tester, String name) async {
  // Revoked elsewhere, at the machine or from another device, without this screen asking again.
  World.backend.keyslotsHeld.removeWhere((held) => held.slot.name == name);
}
