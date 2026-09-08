import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was created
///
/// Read off the socket. Every check runs with `dryRun`, so until the last press there is nothing
/// on that machine to leave behind — and a screen showing a preview while having written a file
/// is exactly the failure this guards.
Future<void> nothingWasCreated(WidgetTester tester) async {
  expect(World.backend.creations.every((asked) => asked.preview), isTrue,
      reason: 'a project file was written before anybody agreed to it');
}
