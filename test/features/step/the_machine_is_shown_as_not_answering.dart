import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine is shown as not answering
Future<void> theMachineIsShownAsNotAnswering(WidgetTester tester) async {
  // Named by what a person calls it, on its rail entry and in its title alike.
  expect(find.byTooltip('${World.machines.current.name}: Not answering'), findsWidgets);
}
