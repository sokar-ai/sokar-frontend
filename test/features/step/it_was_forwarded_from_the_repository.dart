import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was forwarded from the repository {'payments-api'}
Future<void> itWasForwardedFromTheRepository(WidgetTester tester, String repository) async {
  // Forwarded from anywhere else, it would be the other repository's `migrate` that went upstream.
  expect(World.backend.approvals, hasLength(1));
  expect(World.backend.approvals.single.repository, repository);
}
