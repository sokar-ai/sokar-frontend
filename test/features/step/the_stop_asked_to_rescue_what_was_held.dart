import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the stop asked to rescue what was held
Future<void> theStopAskedToRescueWhatWasHeld(WidgetTester tester) async {
  // What went down the socket, not what the screen says about it: rescue and purge differ by one
  // parameter, and getting that one wrong destroys the thing the refusal was protecting.
  expect(World.backend.stops.last.rescue, isTrue);
  expect(World.backend.stops.last.purge, isNull);
}
