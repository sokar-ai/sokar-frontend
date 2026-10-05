import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was decided about any message
Future<void> nothingWasDecidedAboutAnyMessage(WidgetTester tester) async {
  expect(World.backend.released, isEmpty);
}
