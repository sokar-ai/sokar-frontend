import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: this device keeps the key the machine was given
Future<void> thisDeviceKeepsTheKeyTheMachineWasGiven(WidgetTester tester) async {
  // Read off the store and the socket, not the screen: the screen never shows a key.
  final kept = await World.keys.read(World.backend.nodeId);
  expect(kept, isNotNull, reason: 'this device keeps no key for the machine');
  final held = World.backend.keyslotsHeld.where((each) => each.share == kept!.share);
  expect(held, hasLength(1), reason: 'the machine holds no slot for the key kept here');
  expect(kept!.slot, held.single.slot.id);
}
