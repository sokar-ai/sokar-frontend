import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was in the repository {'payments-api'}
Future<void> theLaunchWasInTheRepository(WidgetTester tester, String name) async {
  expect(World.backend.starts.last.repository, name);
}
