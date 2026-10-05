import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: only the token {'ghp_admin'} may add deploy keys
Future<void> onlyTheTokenMayAddDeployKeys(WidgetTester tester, String token) async {
  World.forge.keysOnlyWith = token;
  World.forge.alsoAccepted.add(token);
}
