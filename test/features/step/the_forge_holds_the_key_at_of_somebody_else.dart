import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge holds the key {'ci deploy'} at {'acme/api'} of somebody else
Future<void> theForgeHoldsTheKeyAtOfSomebodyElse(WidgetTester tester, String title, String repository) async {
  await World.forge.addDeployKey(repository, title: title, key: 'ssh-ed25519 AAAAci ci@example', readOnly: true);
}
