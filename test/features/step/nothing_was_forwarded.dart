import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was forwarded
Future<void> nothingWasForwarded(WidgetTester tester) async {
  expect(World.forwards, isEmpty);
}
