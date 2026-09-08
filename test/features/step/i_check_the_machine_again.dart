import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I check the machine again
Future<void> iCheckTheMachineAgain(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('check-again')));
  await World.settle(tester);
}
