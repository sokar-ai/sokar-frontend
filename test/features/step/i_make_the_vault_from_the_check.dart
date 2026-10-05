import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I make the vault from the check
Future<void> iMakeTheVaultFromTheCheck(WidgetTester tester) async {
  await World.tapInView(tester, 'connection-make-vault');
}
