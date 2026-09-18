import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I begin opening the store with this device
Future<void> iBeginOpeningTheStoreWithThisDevice(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('vault-act')));
  await World.settle(tester);
}
