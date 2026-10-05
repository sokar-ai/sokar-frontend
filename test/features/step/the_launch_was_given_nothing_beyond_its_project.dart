import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was given nothing beyond its project
Future<void> theLaunchWasGivenNothingBeyondItsProject(WidgetTester tester) async {
  expect(World.backend.startedWith.last, isEmpty);
}
