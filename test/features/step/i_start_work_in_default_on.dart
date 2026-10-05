import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start work in default on {'git@example.org:acme/tools.git'}
Future<void> iStartWorkInDefaultOn(WidgetTester tester, String address) async {
  await tester.enterText(find.byKey(const Key('default-address')), address);
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('default-start-new')));
  await World.settle(tester);
}
