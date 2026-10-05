import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the task that pushed was asked nothing
Future<void> theTaskThatPushedWasAskedNothing(WidgetTester tester) async {
  World.backend.theInstruction = '';
}
