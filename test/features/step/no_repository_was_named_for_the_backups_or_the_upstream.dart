import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no repository was named for the backups or the upstream
Future<void> noRepositoryWasNamedForTheBackupsOrTheUpstream(WidgetTester tester) async {
  expect(World.backend.backupsAskedIn, isNotEmpty);
  expect(World.backend.backupsAskedIn, everyElement(isNull));
  expect(World.backend.restoredIn, everyElement(isNull));
  expect(World.backend.syncedIn, <String?>[null]);
}
