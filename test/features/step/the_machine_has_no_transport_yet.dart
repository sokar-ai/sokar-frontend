import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine has no transport yet
Future<void> theMachineHasNoTransportYet(WidgetTester tester) async {
  World.setup.lists = '{"packages": ['
      '{"name": "sokar-agent-claude", "kind": "agent", "description": "Claude Code", '
      '"installed": false, "version": "1.0.0"}, '
      '{"name": "sokar-message-transport-matrix", "kind": "transport", '
      '"description": "Matrix transport", "installed": false, "version": "1.0.0"}, '
      '{"name": "sokar-matrix-homeserver", "kind": "homeserver", '
      '"description": "A Matrix homeserver on this machine", "installed": false, "version": "1.0.0"}]}';
}
