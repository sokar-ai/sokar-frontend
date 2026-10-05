import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was dropped
Future<void> nothingWasDropped(WidgetTester tester) async {
  expect(World.backend.rejections, isEmpty);
}
