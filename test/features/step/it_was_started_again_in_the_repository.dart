import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was started again in the repository {'payments-api'}
Future<void> itWasStartedAgainInTheRepository(WidgetTester tester, String repository) async {
  expect(World.backend.startedAgain, hasLength(1));
  expect(World.backend.startedAgain.single.repository, repository);
}
