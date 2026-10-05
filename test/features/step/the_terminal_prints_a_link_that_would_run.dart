import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the terminal prints a link that would run {'file:///usr/bin/xcalc'}
Future<void> theTerminalPrintsALinkThatWouldRun(WidgetTester tester, String address) async {
  World.terminals.last.prints('\x1b]8;;$address\x1b\\press me\x1b]8;;\x1b\\\r\n');
  await World.settle(tester);
}
