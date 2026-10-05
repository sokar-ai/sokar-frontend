import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I type {'ls -l'} into the session
Future<void> iTypeIntoTheSession(WidgetTester tester, String input) async {
  World.sessions.current!.type(input);
  await World.settle(tester);
}
