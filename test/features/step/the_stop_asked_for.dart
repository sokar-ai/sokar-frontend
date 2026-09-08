import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the stop asked for {'sokar-checkout-shell'}
Future<void> theStopAskedFor(WidgetTester tester, String task) async {
  // Recreating is two calls and the stop is the first. Read off the socket: a screen showing a
  // launch while nothing was stopped would leave two containers.
  expect(World.backend.stops, isNotEmpty);
  expect(World.backend.stops.last.task, task);
}
