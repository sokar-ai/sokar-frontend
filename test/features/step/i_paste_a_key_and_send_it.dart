import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I paste a key and send it
Future<void> iPasteAKeyAndSendIt(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('store-paste')));
  await tester.enterText(find.byKey(const Key('store-paste')),
      '-----BEGIN OPENSSH PRIVATE KEY-----\npasted\n-----END OPENSSH PRIVATE KEY-----');
  await World.settle(tester);
  await World.tapInView(tester, 'store-send-pasted');
}
