import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine says the log {'events.jsonl'} holds {'what the firewall blocked'}
Future<void> theMachineSaysTheLogHolds(WidgetTester tester, String log, String what) async {
  // The sentence belongs to the end that knows which files exist and what each one is for.
  // Nothing at this end composes it, and nothing here may guess it for a file it does not know.
  World.backend.whatTheLogsHold[log] = what;
}
