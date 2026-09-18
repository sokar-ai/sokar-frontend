import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine cannot enroll devices yet
Future<void> theMachineCannotEnrollDevicesYet(WidgetTester tester) async {
  World.backend.keyslotsUnknown = true;
}
