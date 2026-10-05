import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no push went upstream
Future<void> noPushWentUpstream(WidgetTester tester) async {
  expect(World.backend.approvals, isEmpty);
}
