import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the keystore of this device refuses with {'no Secret Service is running'}
Future<void> theKeystoreOfThisDeviceRefusesWith(WidgetTester tester, String reason) async {
  World.keys.refusing = reason;
}
