import 'package:flutter_test/flutter_test.dart';

import 'i_look_at_the_forges_repository.dart';

/// Usage: I start working on {'acme/api'} on the machine
Future<void> iStartWorkingOnOnTheMachine(WidgetTester tester, String repository) async {
  await fromTheRepositorysMenu(tester, repository, 'bind');
}
