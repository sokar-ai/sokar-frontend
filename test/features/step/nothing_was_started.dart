import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was started
Future<void> nothingWasStarted(WidgetTester tester) async {
  // Asked before anything is created — the whole point of the preflight.
  expect(World.backend.starts, isEmpty);
}
