import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I switch to the machine {'elsewhere'}
Future<void> iSwitchToTheMachine(WidgetTester tester, String name) async {
  expect(railEntryFor(name), findsOneWidget, reason: '$name is not on the rail');
  await tapOnScreen(tester, railEntryFor(name));
  await World.settle(tester);
}
