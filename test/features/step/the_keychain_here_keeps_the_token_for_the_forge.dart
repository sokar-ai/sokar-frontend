import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the keychain here keeps the token {'ghp_accepted'} for the forge
Future<void> theKeychainHereKeepsTheTokenForTheForge(WidgetTester tester, String token) async {
  await World.forgeTokens.write('github.com', token);
}
