import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was given to the machine
Future<void> nothingWasGivenToTheMachine(WidgetTester tester) async {
  expect(World.setup.stored, isEmpty);
}
