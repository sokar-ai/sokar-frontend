import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the token may not remove deploy keys at {'acme/backend'}
Future<void> theTokenMayNotRemoveDeployKeysAt(WidgetTester tester, String repository) async {
  World.forge.refusesRemovingAt.add(repository);
}
