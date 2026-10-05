import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge holds no key of the machine at {'acme/api'} or {'acme/backend'}
Future<void> theForgeHoldsNoKeyOfTheMachineAtOr(WidgetTester tester, String one, String other) async {
  for (final repository in <String>[one, other]) {
    expect(World.forge.keysOf[repository] ?? const <Object>[], isEmpty, reason: repository);
  }
}
