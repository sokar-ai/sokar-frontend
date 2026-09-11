import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing more was asked of the backend
Future<void> nothingMoreWasAskedOfTheBackend(WidgetTester tester) async {
  // Leaving a refusal alone must be exactly that. A second Remove here would be the interface
  // deciding something it was asked not to decide.
  expect(World.backend.removals, hasLength(1));
}
