import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine has no vault
Future<void> theMachineHasNoVault(WidgetTester tester) async {
  World.backend.keyslotsHeld.clear();
}
