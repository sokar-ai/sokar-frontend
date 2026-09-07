import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: raising a forward will fail with {'Host key verification failed.'}
Future<void> raisingAForwardWillFailWith(WidgetTester tester, String words) async {
  World.forwardsFailWith = words;
}
