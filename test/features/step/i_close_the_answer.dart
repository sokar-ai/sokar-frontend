import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I close the answer
Future<void> iCloseTheAnswer(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('vault-done')));
  await World.settle(tester);
}
