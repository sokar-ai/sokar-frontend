import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the vault from the check
Future<void> iOpenTheVaultFromTheCheck(WidgetTester tester) async {
  await World.tapInView(tester, 'connection-open-vault');
}
