import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine has answered
Future<void> theMachineHasAnswered(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await World.settle(tester);
}
