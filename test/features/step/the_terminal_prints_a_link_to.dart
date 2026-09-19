import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the terminal prints a link to {'https://claude.com/cai/oauth/authorize?code=true'}
Future<void> theTerminalPrintsALinkTo(WidgetTester tester, String address) async {
  // As Claude Code writes its login page: an OSC 8 hyperlink around the text it shows.
  World.terminals.last.prints('\x1b]8;id=login;$address\x1b\\$address\x1b]8;;\x1b\\\r\nPaste code here if prompted > ');
  await World.settle(tester);
}
