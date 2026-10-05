import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine knows no such task
Future<void> theMachineKnowsNoSuchTask(WidgetTester tester) async {
  World.backend.workHeldIsNoSuchTask = true;
}
