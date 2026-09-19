import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge says {'/home/me/.ssh/id_ed25519'} logs in as {'Hi fuinorg/utils4j!'}
Future<void> theForgeSaysLogsInAs(WidgetTester tester, String path, String greeting) async {
  World.backend.identities[path] = greeting;
}
