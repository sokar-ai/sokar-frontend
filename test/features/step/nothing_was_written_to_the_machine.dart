import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was written to the machine
Future<void> nothingWasWrittenToTheMachine(WidgetTester tester) async {
  expect(World.backend.destinationWrites.where((each) => !each.dryRun), isEmpty);
}
