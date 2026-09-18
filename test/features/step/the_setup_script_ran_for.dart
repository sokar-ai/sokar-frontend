import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the setup script ran for {'agents'}
Future<void> theSetupScriptRanFor(WidgetTester tester, String user) async {
  expect(World.setup.asRootRan.last, startsWith("bash /root/sokar-setup.sh --user '$user'"));
}
