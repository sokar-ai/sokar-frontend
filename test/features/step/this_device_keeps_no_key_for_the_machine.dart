import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: this device keeps no key for the machine
Future<void> thisDeviceKeepsNoKeyForTheMachine(WidgetTester tester) async {
  expect(await World.keys.read(World.backend.nodeId), isNull);
}
