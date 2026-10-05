import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: default no longer holds {'api'}
Future<void> defaultNoLongerHolds(WidgetTester tester, String name) async {
  expect(World.backend.inDefault.where((each) => each.name == name), isEmpty);
}
