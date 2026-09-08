import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I shut the store
Future<void> iShutTheStore(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('lock-the-store')));
  await World.settle(tester);
}
