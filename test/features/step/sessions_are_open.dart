import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: {2} sessions are open
Future<void> sessionsAreOpen(WidgetTester tester, int count) async {
  expect(World.sessions.all, hasLength(count));
}
