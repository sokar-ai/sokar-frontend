import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no session is open
Future<void> noSessionIsOpen(WidgetTester tester) async {
  expect(World.sessions.current, isNull);
  // The way in is closed from this side, which is what leaving means. Nothing was told to stop.
  expect(World.terminals.last.closed, isTrue);
}
