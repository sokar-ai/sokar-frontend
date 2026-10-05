import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: I offer the public half of a key of this computer for {'ssh://e2e-pub.invalid/'} in the wizard
Future<void> iOfferThePublicHalfOfAKeyOfThisComputerForInTheWizard(WidgetTester tester, String match) async {
  final pair = await aThrowawayKeyPair();
  await openTheConnectionWizard(tester);
  await tester.enterText(find.byKey(const Key('connection-match')), match);
  await choose(tester, 'connection-kind', 'kind-SSH_KEY');
  await tester.tap(find.byKey(const Key('wizard-next')));
  await pumpUntilShown(tester, const Key('connection-way'));
  await choose(tester, 'connection-way', 'way-computer');
  await tester.enterText(find.byKey(const Key('connection-private-key')), pair.public);
  await pumpFor(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await pumpFor(tester);
}
