import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: work is blocked reaching {'api.example.test:443'} past its deadline
Future<void> workIsBlockedReachingPastItsDeadline(WidgetTester tester, String where) async {
  final ended = DateTime.now().subtract(const Duration(minutes: 1));
  World.backend.asking.add(World.blocked(where, deadline: ended.toUtc().toIso8601String()));
  await World.settle(tester);
}
