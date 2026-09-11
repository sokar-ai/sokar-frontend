import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: work is blocked reaching {'api.example.test:443'} with no deadline
Future<void> workIsBlockedReachingWithNoDeadline(WidgetTester tester, String where) async {
  // Sent empty, which is "never runs out" — not absent, which is a daemon that says nothing.
  World.backend.asking.add(World.blocked(where, deadline: ''));
  await World.settle(tester);
}
