import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: a key the machine already knows is kept as {'sokar-the-build-machine'}
///
/// What the first wizard left behind on this computer when it prepared the machine.
Future<void> aKeyTheMachineAlreadyKnowsIsKeptAs(WidgetTester tester, String name) async {
  await World.setup.save(await World.setup.generate('sokar the build machine'), name);
}
