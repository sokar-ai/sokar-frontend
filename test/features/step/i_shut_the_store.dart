import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I shut the store
Future<void> iShutTheStore(WidgetTester tester) async {
  // The lock beside the stop; the answer stays in the dialog until it is closed.
  await tester.tap(find.byKey(const Key('vault-act')));
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('vault-confirm')));
  await World.settle(tester);
}
