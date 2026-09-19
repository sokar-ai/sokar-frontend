import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_begin_enrolling_this_device.dart';

/// Usage: I enroll this device as {'laptop'}
Future<void> iEnrollThisDeviceAs(WidgetTester tester, String name) async {
  await iBeginEnrollingThisDevice(tester);
  await tester.enterText(find.byKey(const Key('device-name')), name);
  await tester.pump();
  await tester.tap(find.byKey(const Key('vault-confirm')));
  await World.settle(tester);
}
