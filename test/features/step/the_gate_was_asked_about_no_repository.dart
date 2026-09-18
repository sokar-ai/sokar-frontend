import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the gate was asked about no repository
Future<void> theGateWasAskedAboutNoRepository(WidgetTester tester) async {
  expect(World.backend.gateAskedIn, isNotEmpty);
  expect(World.backend.gateAskedIn, everyElement(isNull));
  expect(World.backend.reviewedIn, everyElement(isNull));
  expect(World.backend.approvals.single.repository, isNull);
}
