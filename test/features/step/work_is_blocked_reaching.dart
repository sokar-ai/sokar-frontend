import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: work is blocked reaching {'api.example.test:443'}
Future<void> workIsBlockedReaching(WidgetTester tester, String where) async {
  World.backend.asking.add(World.blocked(where));
  await World.settle(tester);
}
