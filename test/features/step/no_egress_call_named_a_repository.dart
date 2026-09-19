import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no egress call named a repository
Future<void> noEgressCallNamedARepository(WidgetTester tester) async {
  expect(World.backend.egressAskedIn, isNotEmpty);
  expect(World.backend.egressAskedIn, everyElement(isNull));
  expect(World.backend.egressChangedIn, everyElement(isNull));
}
