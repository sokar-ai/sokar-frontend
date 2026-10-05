import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/its_forge.dart';
import '../support/world.dart';

/// Usage: I remove the machine
Future<void> iRemoveTheMachine(WidgetTester tester) async {
  await openItsForge(tester);
  await tester.ensureVisible(find.byKey(const Key('binding-remove')));
  await tester.tap(find.byKey(const Key('binding-remove')));
  await World.settle(tester);
}
