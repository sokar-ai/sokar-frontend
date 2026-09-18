import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked without a project file
Future<void> theMachineWasAskedWithoutAProjectFile(WidgetTester tester) async {
  expect(World.backend.creations, isNotEmpty);
  expect(World.backend.creations.map((asked) => asked.file), everyElement(isEmpty));
}
