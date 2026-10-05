import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I remove the machines' keys there first
Future<void> iRemoveTheMachinesKeysThereFirst(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('forge-remove-with-keys')));
  await World.settle(tester);
}
