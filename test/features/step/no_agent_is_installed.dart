import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';

import '../support/world.dart';

/// Usage: no agent is installed
Future<void> noAgentIsInstalled(WidgetTester tester) async {
  // 69: nothing ran. A refusal, not a failed run, and there is no log to offer.
  World.backend.launch.addError(const OperationFailed(69));
  await World.backend.launch.close();
  await World.settle(tester);
}
