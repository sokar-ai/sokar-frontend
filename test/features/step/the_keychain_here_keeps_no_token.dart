import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the keychain here keeps no token
Future<void> theKeychainHereKeepsNoToken(WidgetTester tester) async {
  expect(await World.forgeTokens.read('github.com'), isNull);
}
