import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine fails to say whether work can start, with {'the vault could not be read'}
Future<void> theMachineFailsToSayWhetherWorkCanStartWith(WidgetTester tester, String message) async {
  World.backend.canStartFails = message;
}
