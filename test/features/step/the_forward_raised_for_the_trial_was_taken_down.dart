import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forward raised for the trial was taken down
Future<void> theForwardRaisedForTheTrialWasTakenDown(WidgetTester tester) async {
  expect(World.forwardsAsked, isNotEmpty, reason: 'nothing was raised for the trial');
  expect(World.trialForwards, isEmpty, reason: 'the trial left its forward running');
  expect(World.forwardsHeld, isEmpty, reason: 'a trial is not a machine being watched');
}
