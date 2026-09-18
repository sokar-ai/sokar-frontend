import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I enroll this device as {'laptop'}
Future<void> iEnrollThisDeviceAs(WidgetTester tester, String name) async {
  await World.reach(tester, find.byKey(const Key('enroll-this-device')));
  await tester.tap(find.byKey(const Key('enroll-this-device')));
  await World.settle(tester);
  await tester.enterText(find.byKey(const Key('device-name')), name);
  await tester.pump();
  await tester.tap(find.byKey(const Key('enroll-confirm')));
  await World.settle(tester);
}
