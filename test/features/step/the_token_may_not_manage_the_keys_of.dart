import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the token may not manage the keys of {'acme/api'}
Future<void> theTokenMayNotManageTheKeysOf(WidgetTester tester, String repository) async {
  World.forge.tokenMayNotManageKeysOf.add(repository);
}
