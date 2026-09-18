import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the setup script has not run yet
Future<void> theSetupScriptHasNotRunYet(WidgetTester tester) async {
  // Fetching it and asking for --show is all root has done.
  expect(World.setup.asRootRan, hasLength(1));
  expect(World.setup.asRootRan.single, contains('--show'));
}
