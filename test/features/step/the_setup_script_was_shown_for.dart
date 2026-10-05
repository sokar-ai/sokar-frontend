import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the setup script was shown for {'builder'}
Future<void> theSetupScriptWasShownFor(WidgetTester tester, String user) async {
  expect(World.setup.asRootRan.last, contains("--user $user --show"));
}
