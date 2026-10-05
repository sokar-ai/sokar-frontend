import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the unlock terminal ends
Future<void> theUnlockTerminalEnds(WidgetTester tester) async {
  World.terminals.last.endsWith(0);
  await World.settle(tester);
}
