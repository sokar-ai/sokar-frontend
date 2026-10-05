import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I run the setup script
Future<void> iRunTheSetupScript(WidgetTester tester) async {
  await World.tapInView(tester, 'run-setup');
}
