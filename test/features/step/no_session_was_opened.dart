import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no session was opened
Future<void> noSessionWasOpened(WidgetTester tester) async {
  expect(World.sessions.current, isNull);
}
