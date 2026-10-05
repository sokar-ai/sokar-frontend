import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: I check the variable {'E2E_NOT_SET'} as a token for {'https://e2e-var.invalid/'} in the wizard
Future<void> iCheckTheVariableAsATokenForInTheWizard(WidgetTester tester, String variable, String match) async {
  await openTheConnectionWizard(tester);
  await tester.enterText(find.byKey(const Key('connection-match')), match);
  await choose(tester, 'connection-kind', 'kind-TOKEN');
  await tester.tap(find.byKey(const Key('wizard-next')));
  await pumpUntilShown(tester, const Key('connection-way'));
  await choose(tester, 'connection-way', 'way-variable');
  await tester.enterText(find.byKey(const Key('connection-variable')), variable);
  await pumpFor(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await untilTheMachineChecked(tester);
}
