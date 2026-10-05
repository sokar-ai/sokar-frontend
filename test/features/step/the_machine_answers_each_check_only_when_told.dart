import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine answers each check only when told
Future<void> theMachineAnswersEachCheckOnlyWhenTold(WidgetTester tester) async {
  World.backend.holdingChecks = true;
}
