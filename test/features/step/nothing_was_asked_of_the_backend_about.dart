import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was asked of the backend about {'checkout'}
Future<void> nothingWasAskedOfTheBackendAbout(WidgetTester tester, String project) async {
  // Selecting is a decision about where to look, never about the thing looked at. Read off the
  // socket rather than off the screen: a call that changed something would not show here.
  expect(World.backend.starts, isEmpty);
  expect(World.backend.stops, isEmpty);
  expect(World.backend.changes, isEmpty);
  expect(World.backend.approvals, isEmpty);
  expect(World.backend.widenings, isEmpty);
}
