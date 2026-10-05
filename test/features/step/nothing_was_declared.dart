import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was declared
Future<void> nothingWasDeclared(WidgetTester tester) async {
  expect(World.backend.declared, isEmpty);
}
