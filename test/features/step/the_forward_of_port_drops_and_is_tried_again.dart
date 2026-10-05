import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forward of port {'8008'} drops and is tried again
///
/// It stops answering, and the window's next look, every 30 seconds, raises it again.
Future<void> theForwardOfPortDropsAndIsTriedAgain(WidgetTester tester, String port) async {
  World.forwardsAnswer = false;
  await tester.pump(const Duration(seconds: 31));
  await World.settle(tester);
}
