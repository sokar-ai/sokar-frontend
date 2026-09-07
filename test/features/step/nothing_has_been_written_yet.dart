import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing has been written yet
Future<void> nothingHasBeenWrittenYet(WidgetTester tester) async {
  // Every call so far asked only what it would do. This is the most consequential edit in the
  // product, and applying it without showing the effect is worse than the file editor it replaces.
  expect(World.backend.changes.every((change) => change.preview), isTrue,
      reason: 'something was written without being previewed');
}
