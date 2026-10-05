import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine answers the later check, then the earlier one
Future<void> theMachineAnswersTheLaterCheckThenTheEarlierOne(WidgetTester tester) async {
  final held = World.backend.heldChecks;
  expect(held, hasLength(2), reason: 'two checks were meant to be out at once');
  held.last.complete();
  await World.settle(tester);
  held.first.complete();
  await World.settle(tester);
}
