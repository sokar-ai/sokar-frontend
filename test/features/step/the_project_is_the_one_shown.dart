import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the project {'api'} is the one shown
///
/// Selected on its machine, so the tree marks it and its page is what the machine shows; where the
/// machine's projects are folded away, the selection is what opening them shows.
Future<void> theProjectIsTheOneShown(WidgetTester tester, String project) async {
  expect(World.fleet.selectedProject?.name, project);
}
