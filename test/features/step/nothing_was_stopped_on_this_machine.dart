import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was stopped on this machine
Future<void> nothingWasStoppedOnThisMachine(WidgetTester tester) async {
  expect(World.backend.stops, isEmpty);
}
