import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I begin enrolling this device
Future<void> iBeginEnrollingThisDevice(WidgetTester tester) async {
  // From the machine's menu: enrolling is not a task the title bar should carry.
  await tester.tap(find.byKey(const Key('machine-menu')).first);
  await World.settle(tester);
  await tester.tap(find.text('Enroll this device on this machine').last);
  await World.settle(tester);
}
