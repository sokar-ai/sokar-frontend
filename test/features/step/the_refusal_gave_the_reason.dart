import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the refusal gave the reason {'not before the tests pass'}
Future<void> theRefusalGaveTheReason(WidgetTester tester, String reason) async {
  expect(World.backend.refusalReasons, <String>[reason]);
}
