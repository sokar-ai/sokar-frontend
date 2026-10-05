import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/its_forge.dart';
import '../support/world.dart';

/// Usage: I look at the changes waiting at the machine
Future<void> iLookAtTheChangesWaitingAtTheMachine(WidgetTester tester) async {
  await openItsForge(tester);
  await tester.ensureVisible(find.byKey(const Key('binding-changes')));
  await tester.tap(find.byKey(const Key('binding-changes')));
  await World.settle(tester);
}
