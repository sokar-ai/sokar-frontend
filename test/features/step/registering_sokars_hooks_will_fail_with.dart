import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: registering Sokar's hooks will fail with {'podman: cannot write hooks.d'}
Future<void> registeringSokarsHooksWillFailWith(WidgetTester tester, String said) async {
  World.setup.registeringFails = said;
}
