import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the store with this device {'for an hour'}
Future<void> iOpenTheStoreWithThisDevice(WidgetTester tester, String howLong) async {
  await World.reach(tester, find.byKey(const Key('unlock-with-this-device')));
  await tester.tap(find.byKey(const Key('unlock-with-this-device')));
  await World.settle(tester);
  await tester.tap(find.text(howLong));
  await tester.pump();
  await tester.tap(find.byKey(const Key('open-confirm')));
  await World.settle(tester);
}
