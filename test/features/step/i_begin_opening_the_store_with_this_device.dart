import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I begin opening the store with this device
Future<void> iBeginOpeningTheStoreWithThisDevice(WidgetTester tester) async {
  await World.reach(tester, find.byKey(const Key('unlock-with-this-device')));
  await tester.tap(find.byKey(const Key('unlock-with-this-device')));
  await World.settle(tester);
}
