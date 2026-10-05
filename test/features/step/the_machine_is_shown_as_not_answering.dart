import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: the machine is shown as not answering
Future<void> theMachineIsShownAsNotAnswering(WidgetTester tester) async {
  // Named by what a person calls it, on the list of machines, where each says how it stands.
  await lookingAtTheMachines(tester, () async {
    expect(find.byTooltip('${World.machines.current.name}: Not answering'), findsWidgets);
  });
}
