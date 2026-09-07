import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was asked for nothing in particular
Future<void> theLaunchWasAskedForNothingInParticular(WidgetTester tester) async {
  // The backend accepts a prompt with SHELL and records SHELL — a run nobody is attached to,
  // described as one somebody is driving. Leaving a prompt behind in the box must not send it.
  expect(World.backend.starts, isNotEmpty);
  expect(World.backend.starts.last.prompt, isNull);
}
