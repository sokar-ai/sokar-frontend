import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: every machine was stopped
Future<void> everyMachineWasStopped(WidgetTester tester) async {
  // Off the sockets: a real stop is a panic without dryRun, on each machine.
  expect(World.backend.panics, contains(false), reason: 'this machine was not stopped');
  expect(World.elsewhere.panics, contains(false), reason: 'elsewhere was not stopped');
}
