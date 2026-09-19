import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine cannot list its keys
Future<void> theMachineCannotListItsKeys(WidgetTester tester) async {
  World.backend.keysOnTheMachine = null;
}
