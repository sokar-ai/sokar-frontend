import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I open the details of {'this machine'}
Future<void> iOpenTheDetailsOf(WidgetTester tester, String machine) async {
  await toTheMachines(tester);
  await tester.tap(find.byKey(ValueKey<String>('machines-row $machine')));
  await World.settle(tester);
}
