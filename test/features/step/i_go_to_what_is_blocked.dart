import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go to what is blocked
///
/// A blocked connection is a question on its work's tile, and every one of them is on what needs
/// a person.
Future<void> iGoToWhatIsBlocked(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byKey(const Key('machine-tree')), matching: find.text('Needs you')));
  await World.settle(tester);
}
