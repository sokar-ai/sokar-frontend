import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine is shown as not answering
Future<void> theMachineIsShownAsNotAnswering(WidgetTester tester) async {
  // Named by what a person calls it, not by what the transport calls it: the label beside the
  // icon and the sentence in the tooltip have to agree, or one of them is about something else.
  expect(find.byTooltip('${World.machines.current.name}: Not answering'), findsOneWidget);
}
