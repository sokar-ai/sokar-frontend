import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_store_the_credential_from_the_start.dart';

/// Usage: I log in with the agent from the start
Future<void> iLogInWithTheAgentFromTheStart(WidgetTester tester) async {
  askedBeforeStoring = World.backend.canStartAsked;
  await World.tapInView(tester, 'log-in-with-the-agent');
}
