import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: root login was not turned off
Future<void> rootLoginWasNotTurnedOff(WidgetTester tester) async {
  expect(World.setup.asRootRan.where((script) => script.contains('PermitRootLogin')), isEmpty);
}
