import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the agent prints a link of its own to {'https://claude.com/cai/oauth/authorize?code=true'}
Future<void> theAgentPrintsALinkOfItsOwnTo(WidgetTester tester, String address) async {
  // Claude Code's own link, unmarked: the one that ends at a page showing a code.
  World.terminals.last.prints('\x1b]8;id=claude;$address\x1b\\$address\x1b]8;;\x1b\\\r\n');
  await World.settle(tester);
}
