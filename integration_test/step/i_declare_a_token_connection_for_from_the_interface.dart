import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: I declare a token connection for {'https://e2e.invalid/'} from the interface
Future<void> iDeclareATokenConnectionForFromTheInterface(WidgetTester tester, String match) async {
  await switchTo(tester, E2e.name);
  // From the machine's menu, which is where it lives.
  await tester.tap(find.byKey(const Key('machine-menu')).first);
  await pumpFor(tester);
  await tester.tap(find.text('Show how this machine connects out').last);
  await pumpUntil(tester, () => find.byKey(const Key('add-connection')).evaluate().isNotEmpty,
      what: 'the connections of the machine');
  await tester.tap(find.byKey(const Key('add-connection')));
  await pumpFor(tester);
  await tester.enterText(find.byKey(const Key('connection-match')), match);
  await tester.tap(find.byKey(const Key('kind-TOKEN')));
  await pumpFor(tester);
  await tester.tap(find.byKey(const Key('connection-add')));
  await pumpUntil(tester, () => find.byKey(const Key('connection-declared')).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30), what: 'the machine to say what it wrote');
}
