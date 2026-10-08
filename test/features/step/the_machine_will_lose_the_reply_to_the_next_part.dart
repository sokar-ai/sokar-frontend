import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine will lose the reply to the next part
Future<void> theMachineWillLoseTheReplyToTheNextPart(WidgetTester tester) async {
  World.backend.loseTheNextReply = true;
}
