import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine answers
Future<void> theMachineAnswers(WidgetTester tester) async {
  World.setup.holdRoot!.complete();
  World.setup.holdRoot = null;
  await World.settle(tester);
}
