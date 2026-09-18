import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked whether work can start in {'payments-api'}
Future<void> theMachineWasAskedWhetherWorkCanStartIn(WidgetTester tester, String repository) async {
  expect(World.backend.askedAboutRepositories.last, repository);
}
