import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show what the repository {'payments-api'} would open
Future<void> iShowWhatTheRepositoryWouldOpen(WidgetTester tester, String repository) async {
  await World.fromARepositorysMenu(tester, repository, 'opens');
}
