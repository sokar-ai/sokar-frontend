import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I make it here with a passphrase
Future<void> iMakeItHereWithAPassphrase(WidgetTester tester) async {
  await World.tapInView(tester, 'make-in-terminal');
}
