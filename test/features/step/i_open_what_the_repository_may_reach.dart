import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open what the repository {'payments-api'} may reach
Future<void> iOpenWhatTheRepositoryMayReach(WidgetTester tester, String repository) async {
  await World.fromARepositorysMenu(tester, repository, 'reach');
}
