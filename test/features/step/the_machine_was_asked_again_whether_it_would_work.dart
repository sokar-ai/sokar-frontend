import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked again whether it would work
Future<void> theMachineWasAskedAgainWhetherItWouldWork(WidgetTester tester) async {
  expect(World.backend.dryRuns.length, greaterThanOrEqualTo(2));
}
