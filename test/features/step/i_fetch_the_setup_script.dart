import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I fetch the setup script
Future<void> iFetchTheSetupScript(WidgetTester tester) async {
  await World.tapInView(tester, 'show-setup');
}
