import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine can answer again
///
/// The daemon is there again, however it got there. Nothing is told: the interface is trying
/// anyway, which is what makes a machine that comes back come back on its own.
Future<void> theMachineCanAnswerAgain(WidgetTester tester) async {
  World.backend.absent = null;
  await tester.pump(const Duration(seconds: 5));
  await World.settle(tester);
}
