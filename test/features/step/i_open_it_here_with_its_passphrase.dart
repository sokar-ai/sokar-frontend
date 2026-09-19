import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open it here with its passphrase
Future<void> iOpenItHereWithItsPassphrase(WidgetTester tester) async {
  await World.tapInView(tester, 'unlock-in-terminal');
}
