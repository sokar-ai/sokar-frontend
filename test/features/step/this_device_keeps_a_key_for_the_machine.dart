import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: this device keeps a key for the machine
Future<void> thisDeviceKeepsAKeyForTheMachine(WidgetTester tester) async {
  // Whether the machine took it is unknown, and the same key sent again is recognized there.
  expect(await World.keys.read(World.backend.nodeId), isNotNull);
}
