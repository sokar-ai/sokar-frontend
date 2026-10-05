import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: work elsewhere is blocked reaching {'api.example.test:443'}
Future<void> workElsewhereIsBlockedReaching(WidgetTester tester, String where) async {
  World.elsewhere.asking.add(World.blocked(where));
  await World.settle(tester);
}
