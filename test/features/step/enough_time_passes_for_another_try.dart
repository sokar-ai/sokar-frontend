import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: enough time passes for another try
Future<void> enoughTimePassesForAnotherTry(WidgetTester tester) async {
  // A tunnel coming back must not need anybody to notice it has: reconnection is a loop, and the
  // button is only there for somebody who does not want to wait.
  await tester.pump(const Duration(seconds: 5));
  await World.settle(tester);
}
