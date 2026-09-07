import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch asked for the mode {'SHELL'}
Future<void> theLaunchAskedForTheMode(WidgetTester tester, String mode) async {
  // What went down the socket. The mode says whether anybody is going to be there, so a screen
  // that offered one and sent another would be wrong where nobody could see it.
  expect(World.backend.starts, isNotEmpty);
  expect(World.backend.starts.last.mode?.name, mode);
}
