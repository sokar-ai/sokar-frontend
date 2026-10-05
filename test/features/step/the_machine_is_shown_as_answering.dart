import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: the machine is shown as answering
Future<void> theMachineIsShownAsAnswering(WidgetTester tester) async {
  // By the name a person calls it, which is what is written beside the icon.
  // On the list of machines, where each says how it stands.
  await lookingAtTheMachines(tester, () async {
    expect(find.byTooltip('${World.machines.current.name}: Answering'), findsWidgets);
  });
}
