import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the first project on the machine is {'default'}
Future<void> theFirstProjectOnTheMachineIs(WidgetTester tester, String name) async {
  expect(World.fleet.projects.first.name, name);
}
