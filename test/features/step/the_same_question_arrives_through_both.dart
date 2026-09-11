import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the same question arrives through both
Future<void> theSameQuestionArrivesThroughBoth(WidgetTester tester) async {
  // One node reached two ways delivers every question on both connections.
  World.backend.asking.add(World.blocked('api.example.test:443'));
  World.elsewhere.asking.add(World.blocked('api.example.test:443'));
  await World.settle(tester);
}
