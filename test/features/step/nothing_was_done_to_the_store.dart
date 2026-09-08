import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was done to the store
Future<void> nothingWasDoneToTheStore(WidgetTester tester) async {
  // Looking at it is not acting on it. Read off the socket rather than off the screen.
  expect(World.backend.storeAsked, isNotEmpty);
  expect(World.backend.storeAsked.contains('lock'), isFalse);
}
