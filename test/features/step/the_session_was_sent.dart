import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the session was sent {'ls -l'}
Future<void> theSessionWasSent(WidgetTester tester, String input) async {
  expect(World.terminals.last.typed, contains(input));
}
