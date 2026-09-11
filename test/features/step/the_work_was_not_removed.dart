import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the work was not removed
Future<void> theWorkWasNotRemoved(WidgetTester tester) async {
  expect(World.backend.removals, isEmpty);
}
