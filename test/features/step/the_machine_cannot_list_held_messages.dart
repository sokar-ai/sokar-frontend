import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine cannot list held messages
Future<void> theMachineCannotListHeldMessages(WidgetTester tester) async {
  World.backend.withoutHeld = true;
}
