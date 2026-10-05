import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the keychain here keeps the token {'ghp_accepted'}
Future<void> theKeychainHereKeepsTheToken(WidgetTester tester, String token) async {
  expect(await World.forgeTokens.read('github.com'), token);
}
