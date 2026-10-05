import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge refuses a deploy key at {'acme/backend'}
Future<void> theForgeRefusesADeployKeyAt(WidgetTester tester, String repository) async {
  World.forge.refusesAddingAt.add(repository);
}
