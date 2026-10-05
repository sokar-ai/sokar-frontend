import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I paste {'ssh-ed25519 AAAA me@work'} and send it
Future<void> iPasteAndSendIt(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.byKey(const Key('store-paste')));
  await tester.enterText(find.byKey(const Key('store-paste')), text);
  await World.settle(tester);
  await World.tapInView(tester, 'store-send-pasted');
}
