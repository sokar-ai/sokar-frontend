import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked with the project file {'/home/somebody/work/new-thing/project.yml'}
Future<void> theMachineWasAskedWithTheProjectFile(WidgetTester tester, String file) async {
  expect(World.backend.creations.last.file, file);
}
