import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the store with its passphrase from the lock
Future<void> iOpenTheStoreWithItsPassphraseFromTheLock(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('vault-act')).first);
  await World.settle(tester);
}
