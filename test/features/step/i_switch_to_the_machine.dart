import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I switch to the machine {'elsewhere'}
Future<void> iSwitchToTheMachine(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  // Contained rather than equal: a machine whose forward this interface raised says so in the
  // same entry, and the name is what somebody is picking.
  await tester.tap(find
      .ancestor(of: find.textContaining(name), matching: find.byType(MenuItemButton))
      .first);
  await World.settle(tester);
}
