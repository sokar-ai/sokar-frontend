import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: a forward of port {'8765'} is held
Future<void> aForwardOfPortIsHeld(WidgetTester tester, String port) async {
  expect(World.forwards, <int>[int.parse(port)]);
  expect(World.forwardsClosed, isEmpty);
}
