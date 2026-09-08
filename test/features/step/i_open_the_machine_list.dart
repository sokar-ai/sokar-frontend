import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the machine list
///
/// The switcher itself, with nothing chosen — which is where each entry says what kind it is and
/// whether it is a second way in to a node already listed.
Future<void> iOpenTheMachineList(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
}
