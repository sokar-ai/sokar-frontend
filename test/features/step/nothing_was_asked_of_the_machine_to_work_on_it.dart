import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was asked of the machine to work on it
Future<void> nothingWasAskedOfTheMachineToWorkOnIt(WidgetTester tester) async {
  expect(World.backend.follows, isEmpty);
}
