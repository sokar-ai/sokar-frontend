import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the terminal it replaced was closed
Future<void> theTerminalItReplacedWasClosed(WidgetTester tester) async {
  expect(World.terminals, hasLength(greaterThanOrEqualTo(2)));
  expect(World.terminals[World.terminals.length - 2].closed, isTrue);
}
