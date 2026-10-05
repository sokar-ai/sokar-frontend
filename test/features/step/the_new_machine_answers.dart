import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the new machine answers
Future<void> theNewMachineAnswers(WidgetTester tester) async {
  World.backend.answersLater!.complete();
  await World.settle(tester);
}
