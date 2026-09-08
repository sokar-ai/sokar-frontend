import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I switch to the machine {'elsewhere'}
Future<void> iSwitchToTheMachine(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);

  // **The line that *starts* with the name**, not one that contains it. An entry says what kind
  // it is and which node it shares, so *"this machine · the same node as the build machine"*
  // contains the other machine's name — and matching on "contains" switched to the wrong one.
  final entry = find.byWidgetPredicate((widget) =>
      widget is Text && (widget.data ?? '').startsWith(name));

  expect(entry, findsWidgets, reason: '$name is not in the machine list');
  await tester.tap(find.ancestor(of: entry.first, matching: find.byType(MenuItemButton)).first);
  await World.settle(tester);
}
