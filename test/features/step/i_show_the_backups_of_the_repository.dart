import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show the backups of the repository {'payments-api'}
Future<void> iShowTheBackupsOfTheRepository(WidgetTester tester, String repository) async {
  await World.fromARepositorysMenu(tester, repository, 'backups');
}
