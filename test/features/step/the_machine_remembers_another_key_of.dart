import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'the_machine_has_never_met_the_host.dart';

/// Usage: the machine remembers another key of {'example.org'}
Future<void> theMachineRemembersAnotherKeyOf(WidgetTester tester, String host) async {
  await theMachineHasNeverMetTheHost(tester, host);
  World.backend.changedHost = host;
}
