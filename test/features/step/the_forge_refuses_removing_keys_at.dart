import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge refuses removing keys at {'acme/api'}
Future<void> theForgeRefusesRemovingKeysAt(WidgetTester tester, String repository) async {
  World.forge.refusesRemovingAt.add(repository);
}
