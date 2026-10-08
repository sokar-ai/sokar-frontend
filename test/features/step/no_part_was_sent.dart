import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no part was sent
Future<void> noPartWasSent(WidgetTester tester) async {
  expect(World.backend.parts, isEmpty, reason: 'refused here, before a byte was read or sent');
}
