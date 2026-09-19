import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I give the key {'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5'}
Future<void> iGiveTheKey(WidgetTester tester, String key) async {
  await tester.enterText(find.byKey(const Key('follow-key')), key);
  await World.settle(tester);
}
