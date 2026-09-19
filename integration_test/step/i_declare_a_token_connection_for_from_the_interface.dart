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
  // Drawn while the machine is still being asked, and only pressable once it has answered.
  await pumpUntil(
      tester,
      () =>
          find.byKey(const Key('add-connection')).evaluate().isNotEmpty &&
          tester.widget<ButtonStyleButton>(find.byKey(const Key('add-connection'))).onPressed != null,
      what: 'the connections of the machine, read');
  await tester.ensureVisible(find.byKey(const Key('add-connection')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('add-connection')));
  await pumpUntil(tester, () => find.byKey(const Key('connection-match')).evaluate().isNotEmpty,
      what: 'the dialog asking what connection to add');
  await tester.enterText(find.byKey(const Key('connection-match')), match);
  await choose(tester, 'connection-kind', 'kind-TOKEN');
  await tester.tap(find.byKey(const Key('connection-add')));
  await pumpUntil(tester, () => find.byKey(const Key('connection-declared')).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30), what: 'the machine to say what it wrote');
}
