import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';

/// Usage: the repository {'e2e-default'} is removed again from the test machine
Future<void> theRepositoryIsRemovedAgainFromTheTestMachine(WidgetTester tester, String name) async {
  await onTheTestMachine('rm -rf "\$HOME/$name" "\$HOME/$name.git"');
}
