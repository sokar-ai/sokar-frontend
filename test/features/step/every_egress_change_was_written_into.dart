import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: every egress change was written into {'payments-api'}
Future<void> everyEgressChangeWasWrittenInto(WidgetTester tester, String repository) async {
  // The preview and the change alike: a preview about the project would show what somebody did not
  // agree to write into the repository.
  expect(World.backend.egressChangedIn, hasLength(2));
  expect(World.backend.egressChangedIn, everyElement(repository));
}
