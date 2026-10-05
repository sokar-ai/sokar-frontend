import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I copy the public key
Future<void> iCopyThePublicKey(WidgetTester tester) async {
  World.watchTheClipboard(tester);
  await World.tapInView(tester, 'copy-public-key');
}
