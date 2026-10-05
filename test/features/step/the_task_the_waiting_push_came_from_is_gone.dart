import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the task the waiting push came from is gone
Future<void> theTaskTheWaitingPushCameFromIsGone(WidgetTester tester) async {
  World.backend.pushersTaskGone = true;
}
