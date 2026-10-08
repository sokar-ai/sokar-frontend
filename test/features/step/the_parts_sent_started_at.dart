import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the parts sent started at {'0, 0, 1048576, 2097152'}
Future<void> thePartsSentStartedAt(WidgetTester tester, String offsets) async {
  expect(World.backend.parts.map((each) => each.offset).join(', '), offsets);
}
