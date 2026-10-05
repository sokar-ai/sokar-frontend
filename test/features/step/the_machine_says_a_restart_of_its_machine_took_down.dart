import 'package:flutter_test/flutter_test.dart';

import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the machine says a restart of its machine took {'sokar-checkout-shell'} down
Future<void> theMachineSaysARestartOfItsMachineTookDown(WidgetTester tester, String work) async {
  // Sokar's words for it.
  World.theStartWouldBe(work, 'RESUME', detail: 'the machine restarted; starting it brings it back whole');
  // What a start of it answers, measured on Sokar 199.1: no action, exit 0, and the lines it printed.
  World.backend.nextStart = const StartProgress(exitCode: 0, output: <String>[
    "restored  what the machine's restart took: its records, its egress and its tokens",
  ]);
  await World.settle(tester);
}
