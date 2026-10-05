import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the upstream was asked about the repository {'payments-api'}
Future<void> theUpstreamWasAskedAboutTheRepository(WidgetTester tester, String repository) async {
  expect(World.backend.syncedIn, <String?>[repository]);
}
