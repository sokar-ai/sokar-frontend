import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: one agent is shadowed by another copy
Future<void> oneAgentIsShadowedByAnotherCopy(WidgetTester tester) async {
  World.backend.theAgentsItNeverUses = const <ShadowedAgent>[
    ShadowedAgent(
      path: '/usr/libexec/sokar/agents/an-agent',
      usedInstead: '/home/somebody/.local/share/sokar/agents/an-agent',
    ),
  ];
}
