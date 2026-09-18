import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the terminal ends with {0}
Future<void> theTerminalEndsWith(WidgetTester tester, int code) async {
  World.terminals.last.endsWith(code);
  await World.settle(tester);
}
