import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the work {'sokar-checkout-shell'} is idle
Future<void> theWorkIsIdle(WidgetTester tester, String work) async {
  World.theWorkIs(work, activity: 'IDLE');
  await World.settle(tester);
}
