import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was installed by asking
Future<void> nothingWasInstalledByAsking(WidgetTester tester) async {
  expect(World.setup.asRootRan, hasLength(1));
  expect(World.setup.asRootRan.single, contains('--list --json'));
}
