import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the task that pushed was asked {'Round money to the nearest penny'}
Future<void> theTaskThatPushedWasAsked(WidgetTester tester, String asked) async {
  World.backend.theInstruction = asked;
}
