import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the vault from the start with this device {'for an hour'}
Future<void> iOpenTheVaultFromTheStartWithThisDevice(WidgetTester tester, String howLong) async {
  askedBeforeOpening = World.backend.canStartAsked;
  await World.reach(tester, find.byKey(const Key('open-with-this-device')));
  await tester.tap(find.byKey(const Key('open-with-this-device')));
  await World.settle(tester);
  await World.chooseWords(tester, howLong);
  await tester.tap(find.byKey(const Key('vault-confirm')).last);
  await World.settle(tester);
  await tester.tap(find.text('Close').last);
  await World.settle(tester);
}

/// How often whether work can start was asked before the store was opened.
int askedBeforeOpening = 0;
