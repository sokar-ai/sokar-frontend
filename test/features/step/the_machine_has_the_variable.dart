import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine has the variable {'GITLAB_TOKEN'}
Future<void> theMachineHasTheVariable(WidgetTester tester, String name) async {
  World.backend.variablesOnTheMachine.add(name);
}
