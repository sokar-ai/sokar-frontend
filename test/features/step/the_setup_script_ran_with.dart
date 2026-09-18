import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the setup script ran with {'sokar-agent-claude'}
Future<void> theSetupScriptRanWith(WidgetTester tester, String name) async {
  expect(World.setup.asRootRan.last, "bash /root/sokar-setup.sh --user 'agent' --with '$name'\n");
}
