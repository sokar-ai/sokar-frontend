import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forward of port {'8008'} is still held
Future<void> theForwardOfPortIsStillHeld(WidgetTester tester, String port) async {
  expect(World.forwardsClosed, isNot(contains(int.parse(port))));
}
