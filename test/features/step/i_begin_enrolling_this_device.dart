import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I begin enrolling this device
Future<void> iBeginEnrollingThisDevice(WidgetTester tester) async {
  await World.reach(tester, find.byKey(const Key('enroll-this-device')));
  await tester.tap(find.byKey(const Key('enroll-this-device')));
  await World.settle(tester);
}
