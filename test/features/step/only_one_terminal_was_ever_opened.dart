import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: only one terminal was ever opened
Future<void> onlyOneTerminalWasEverOpened(WidgetTester tester) async {
  expect(World.terminals, hasLength(1));
  expect(World.terminals.single.closed, isFalse);
}
