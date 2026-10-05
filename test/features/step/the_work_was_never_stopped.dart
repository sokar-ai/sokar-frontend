import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the work was never stopped
///
/// Read off the socket rather than off the screen. A session that could not be opened, and one
/// somebody left, must both leave the work exactly as it was — and *"nothing happened to it"* is
/// only believable from the calls that were not made.
Future<void> theWorkWasNeverStopped(WidgetTester tester) async {
  expect(World.backend.stops, isEmpty);
}
