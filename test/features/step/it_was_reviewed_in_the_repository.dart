import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was reviewed in the repository {'payments-api'}
Future<void> itWasReviewedInTheRepository(WidgetTester tester, String repository) async {
  expect(World.backend.reviewedIn.last, repository);
}
