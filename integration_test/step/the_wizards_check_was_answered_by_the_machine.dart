import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/remote.dart';

/// Usage: the wizard's check was answered by the machine
Future<void> theWizardsCheckWasAnsweredByTheMachine(WidgetTester tester) async {
  // Whatever the account's vault is like, the sentence is the daemon's, and it is said.
  debugPrint('the check said: $theCheckSaid');
  expect(theCheckSaid, isNotEmpty, reason: 'the dry run answered nothing a person could read');
}
