import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the removal asked to discard what was held
Future<void> theRemovalAskedToDiscardWhatWasHeld(WidgetTester tester) async {
  expect(World.backend.removals.last.force, isTrue);
  expect(World.backend.removals.last.rescue, isNull);
}
