import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the reply port {'42017'} is forwarded
Future<void> theReplyPortIsForwarded(WidgetTester tester, String port) async {
  expect(World.forwards, <int>[int.parse(port)]);
  expect(World.forwardsClosed, isEmpty);
}
