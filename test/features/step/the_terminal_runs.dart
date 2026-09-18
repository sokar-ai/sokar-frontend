import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the terminal runs {'ssh -t sokar-the-build-machine sokar vault init'}
Future<void> theTerminalRuns(WidgetTester tester, String command) async {
  expect(World.terminals.last.command.join(' '), command);
}
