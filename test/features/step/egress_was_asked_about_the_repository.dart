import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: egress was asked about the repository {'payments-api'}
Future<void> egressWasAskedAboutTheRepository(WidgetTester tester, String repository) async {
  expect(World.backend.egressAskedIn.last, repository);
}
