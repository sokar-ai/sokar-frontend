import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to check the answers
Future<void> theMachineWasAskedToCheckTheAnswers(WidgetTester tester) async {
  expect(World.backend.creations, isNotEmpty,
      reason: 'the answers were never checked against the machine');
  expect(World.backend.creations.last.name, 'new-thing');
}
