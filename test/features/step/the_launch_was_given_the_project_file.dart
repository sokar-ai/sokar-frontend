import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was given the project file
Future<void> theLaunchWasGivenTheProjectFile(WidgetTester tester) async {
  // `Project.file`, passed through unchanged. Never built here and never picked from a file
  // dialog: over a forwarded socket there is no filesystem on that machine to pick from.
  expect(World.backend.starts, isNotEmpty);
  expect(World.backend.starts.last.project, '/srv/checkout/project.yml');
}
