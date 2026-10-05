import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine has no credential check
Future<void> theMachineHasNoCredentialCheck(WidgetTester tester) async {
  World.backend.checkIsMissing = true;
}
