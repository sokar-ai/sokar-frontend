import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine answers the refresh
Future<void> theMachineAnswersTheRefresh(WidgetTester tester) async {
  World.backend.refreshHeld!.complete();
  await World.settle(tester);
}
