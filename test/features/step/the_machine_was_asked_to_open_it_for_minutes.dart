import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to open it for {60} minutes
Future<void> theMachineWasAskedToOpenItForMinutes(WidgetTester tester, int minutes) async {
  expect(World.backend.unlocksFor, <int?>[minutes]);
}
