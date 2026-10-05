import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forward of port {'8765'} is taken down
Future<void> theForwardOfPortIsTakenDown(WidgetTester tester, String port) async {
  expect(World.forwardsClosed, <int>[int.parse(port)]);
}
