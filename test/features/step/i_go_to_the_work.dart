import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go to the work
Future<void> iGoToTheWork(WidgetTester tester) async {
  // The window opens on what needs a person; acting on a project is going somewhere first.
  await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Work')));
  await World.settle(tester);
}
