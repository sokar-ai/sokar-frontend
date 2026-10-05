import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge also accepts the token {'ghp_work'}
Future<void> theForgeAlsoAcceptsTheToken(WidgetTester tester, String token) async {
  World.forge.alsoAccepted.add(token);
}
