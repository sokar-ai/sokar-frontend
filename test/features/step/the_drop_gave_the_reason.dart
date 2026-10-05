import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the drop gave the reason {'the rounding is still wrong'}
Future<void> theDropGaveTheReason(WidgetTester tester, String reason) async {
  expect(World.backend.rejectionReasons, <String>[reason]);
}
