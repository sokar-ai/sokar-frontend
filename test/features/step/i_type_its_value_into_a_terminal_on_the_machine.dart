import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I type its value into a terminal on the machine
Future<void> iTypeItsValueIntoATerminalOnTheMachine(WidgetTester tester) async {
  await World.tapInView(tester, 'store-in-terminal');
}
