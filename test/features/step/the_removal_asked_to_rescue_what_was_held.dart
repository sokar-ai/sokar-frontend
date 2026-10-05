import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the removal asked to rescue what was held
Future<void> theRemovalAskedToRescueWhatWasHeld(WidgetTester tester) async {
  // What went down the socket, not what the screen says about it: rescue and force differ by one
  // parameter, and getting that one wrong destroys the thing the refusal was protecting.
  expect(World.backend.removals.last.rescue, isTrue);
  expect(World.backend.removals.last.force, isNull);
}
