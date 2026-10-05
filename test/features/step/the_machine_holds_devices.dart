import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine holds {1} devices
Future<void> theMachineHoldsDevices(WidgetTester tester, int count) async {
  expect(World.backend.keyslotsHeld.where((held) => !held.slot.recovery), hasLength(count));
}
