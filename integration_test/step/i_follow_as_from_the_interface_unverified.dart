import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: I follow {'git@github.com:sokar-ai/sokar-project.git'} as {'e2e-hostkey'} from the interface, unverified
Future<void> iFollowAsFromTheInterfaceUnverified(WidgetTester tester, String url, String name) async {
  await switchTo(tester, E2e.name);
  await tester.tap(find.byKey(const Key('follow-a-repository')));
  await pumpFor(tester);
  await tester.enterText(find.byKey(const Key('follow-name')), name);
  await tester.enterText(find.byKey(const Key('follow-url')), url);
  await pumpFor(tester);
  await choose(tester, 'follow-checking', 'follow-unverified');
  await tester.ensureVisible(find.byKey(const Key('follow-it')));
  await tester.tap(find.byKey(const Key('follow-it')));
  await pumpUntil(
      tester,
      () =>
          find.byKey(const Key('follow-says')).evaluate().isNotEmpty ||
          find.byKey(const Key('follow-check-says')).evaluate().isNotEmpty ||
          find.byKey(const Key('follow-problem')).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
      what: 'the machine to answer the follow');
}
