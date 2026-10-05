import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: allowing the key for the work user will fail with {'getent: no such user'}
Future<void> allowingTheKeyForTheWorkUserWillFailWith(WidgetTester tester, String said) async {
  World.setup.allowFails = said;
}
