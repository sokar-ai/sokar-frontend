import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the store with this device {'for an hour'}
Future<void> iOpenTheStoreWithThisDevice(WidgetTester tester, String howLong) async {
  await tester.tap(find.byKey(const Key('vault-act')));
  await World.settle(tester);
  await World.chooseWords(tester, howLong);
  await tester.tap(find.byKey(const Key('vault-confirm')));
  await World.settle(tester);
}
