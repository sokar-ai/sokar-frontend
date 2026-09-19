import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was a dry run in the repository {'payments-api'}
Future<void> theLaunchWasADryRunInTheRepository(WidgetTester tester, String repository) async {
  expect(World.backend.launched.last, isTrue, reason: 'a check must create nothing');
  expect(World.backend.starts.last.repository, repository);
}
