import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I paste the private key {'hunter2'}
Future<void> iPasteThePrivateKey(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.byKey(const Key('connection-private-key')));
  await tester.enterText(find.byKey(const Key('connection-private-key')), text);
  await World.settle(tester);
}
