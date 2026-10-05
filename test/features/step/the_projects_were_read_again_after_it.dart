import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the projects were read again after it
///
/// What waits at the gate is a project's count, read with the projects: read again at once after a
/// push was forwarded, not at the next refresh (walk 8: the badge said 1 after it was through).
Future<void> theProjectsWereReadAgainAfterIt(WidgetTester tester) async {
  expect(World.backend.projectsListedAtTheGate, isNot(-1));
  expect(World.backend.projectsListed, greaterThan(World.backend.projectsListedAtTheGate));
}
