import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I sync the repository {'payments-api'}
Future<void> iSyncTheRepository(WidgetTester tester, String repository) async {
  await World.fromARepositorysMenu(tester, repository, 'sync');
}
