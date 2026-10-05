import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was started again in no repository
Future<void> itWasStartedAgainInNoRepository(WidgetTester tester) async {
  expect(World.backend.startedAgain, hasLength(1));
  expect(World.backend.startedAgain.single.repository, isNull);
}
