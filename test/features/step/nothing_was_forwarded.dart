import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was forwarded
Future<void> nothingWasForwarded(WidgetTester tester) async {
  // Dropping a request must not send anything anywhere. The work stays in the mirror.
  expect(World.backend.approvals, isEmpty);
  expect(World.backend.rejections, hasLength(1));
}
