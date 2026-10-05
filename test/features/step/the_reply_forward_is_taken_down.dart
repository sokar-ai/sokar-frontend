import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the reply forward is taken down
Future<void> theReplyForwardIsTakenDown(WidgetTester tester) async {
  expect(World.forwardsClosed, World.forwards);
}
