import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: only the token {'ghp_writer'} may push
Future<void> onlyTheTokenMayPush(WidgetTester tester, String token) async {
  World.workspace.pushesOnlyWith = token;
  World.forge.alsoAccepted.add(token);
}
