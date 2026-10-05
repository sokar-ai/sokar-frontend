import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was called {'schema-work'}
Future<void> theLaunchWasCalled(WidgetTester tester, String name) async {
  expect(World.backend.starts, isNotEmpty);
  expect(World.backend.starts.last.task, name);
}
