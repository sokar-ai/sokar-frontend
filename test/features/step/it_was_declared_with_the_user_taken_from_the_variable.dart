import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was declared with the user taken from the variable {'GITLAB_USER'}
Future<void> itWasDeclaredWithTheUserTakenFromTheVariable(WidgetTester tester, String name) async {
  // The machine reads a user starting with a dollar from its environment.
  expect(World.backend.declared.single.user, '\$$name');
}
