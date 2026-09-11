import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was raised for the trial
Future<void> nothingWasRaisedForTheTrial(WidgetTester tester) async {
  expect(World.forwardsAsked, isEmpty);
}
