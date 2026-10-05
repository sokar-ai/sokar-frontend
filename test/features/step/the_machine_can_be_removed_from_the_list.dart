import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the machine {'this machine'} can be removed from the list {false}
Future<void> theMachineCanBeRemovedFromTheList(WidgetTester tester, String machine, bool can) async {
  await toTheMachines(tester);
  expect(find.byKey(ValueKey<String>('machines-menu $machine')).evaluate().isNotEmpty, can);
}
