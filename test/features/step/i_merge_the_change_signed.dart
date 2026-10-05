import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I merge the change {'plan'} signed
Future<void> iMergeTheChangeSigned(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.byKey(ValueKey<String>('merge-change $name')));
  await tester.tap(find.byKey(ValueKey<String>('merge-change $name')));
  await World.settle(tester);
}
