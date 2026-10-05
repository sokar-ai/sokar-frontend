import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing is waiting any more
Future<void> nothingIsWaitingAnyMore(WidgetTester tester) async {
  expect(World.fleet.clearance.count, 0);
  expect(find.text('Let it through'), findsNothing);
}
