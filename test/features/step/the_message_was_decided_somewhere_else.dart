import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the message was decided somewhere else
Future<void> theMessageWasDecidedSomewhereElse(WidgetTester tester) async {
  // Still listed on screen, and gone on the machine: read now, it is no longer there.
  World.backend.readable.clear();
}
