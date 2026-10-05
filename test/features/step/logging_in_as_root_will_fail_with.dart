import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: logging in as root will fail with {'Permission denied (publickey).'}
Future<void> loggingInAsRootWillFailWith(WidgetTester tester, String said) async {
  World.setup.rootLoginFails = said;
}
