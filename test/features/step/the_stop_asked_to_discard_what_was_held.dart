import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the stop asked to discard what was held
Future<void> theStopAskedToDiscardWhatWasHeld(WidgetTester tester) async {
  expect(World.backend.stops.last.purge, isTrue);
  expect(World.backend.stops.last.rescue, isNull);
}
