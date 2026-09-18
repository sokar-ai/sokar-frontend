import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: root login was turned off
Future<void> rootLoginWasTurnedOff(WidgetTester tester) async {
  expect(World.setup.asRootRan.last, contains('PermitRootLogin no'));
}
