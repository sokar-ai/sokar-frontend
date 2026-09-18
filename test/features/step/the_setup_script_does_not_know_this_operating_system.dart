import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the setup script does not know this operating system
Future<void> theSetupScriptDoesNotKnowThisOperatingSystem(WidgetTester tester) async {
  World.setup.showEnds = 3;
}
