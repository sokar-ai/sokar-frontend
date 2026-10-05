import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch left the naming to the machine
Future<void> theLaunchLeftTheNamingToTheMachine(WidgetTester tester) async {
  // Nothing is sent rather than an empty string: `Start` names a task when nothing else does,
  // and an empty name is a name somebody typed and deleted.
  expect(World.backend.starts, isNotEmpty);
  expect(World.backend.starts.last.task, isNull);
}
