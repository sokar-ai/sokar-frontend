import 'package:flutter_test/flutter_test.dart';

import 'i_look_at_the_forges_repository.dart';

/// Usage: I use {'acme/api'} as a project
Future<void> iUseAsAProject(WidgetTester tester, String repository) async {
  await fromTheRepositorysMenu(tester, repository, 'bind');
}
