import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the setup script will end with {5}
Future<void> theSetupScriptWillEndWith(WidgetTester tester, int code) async {
  World.setup.prepareEnds = code;
}
