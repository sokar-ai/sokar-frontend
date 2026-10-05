import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to open it without a bound
Future<void> theMachineWasAskedToOpenItWithoutABound(WidgetTester tester) async {
  expect(World.backend.unlocksFor, <int?>[null]);
}
