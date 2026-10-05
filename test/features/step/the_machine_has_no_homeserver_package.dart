import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine has no homeserver package
Future<void> theMachineHasNoHomeserverPackage(WidgetTester tester) async {
  World.setup.homeserverInstalled = false;
}
