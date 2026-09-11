import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I select the project {'checkout'}
Future<void> iSelectTheProject(WidgetTester tester, String project) async {
  // A card narrows the work to it and a second tap widens it back, so a selected one is left alone.
  if (World.fleet.selectedProject?.name == project) return;
  await tapOnScreen(tester, cardFor(project));
  await World.settle(tester);
}
