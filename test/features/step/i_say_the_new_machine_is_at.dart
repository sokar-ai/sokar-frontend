import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I say the new machine is at {'203.0.113.10'}
Future<void> iSayTheNewMachineIsAt(WidgetTester tester, String host) async {
  await tester.enterText(find.byKey(const Key('new-host')), host);
  await World.settle(tester);
}
