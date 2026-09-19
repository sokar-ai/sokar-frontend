import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the vault from the follow
Future<void> iOpenTheVaultFromTheFollow(WidgetTester tester) async {
  await World.tapInView(tester, 'follow-unlock');
}
