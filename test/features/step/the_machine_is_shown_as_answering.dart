import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine is shown as answering
Future<void> theMachineIsShownAsAnswering(WidgetTester tester) async {
  // By the name a person calls it, which is what is written beside the icon.
  expect(find.byTooltip('${World.machines.current.name}: Answering'), findsOneWidget);
}
