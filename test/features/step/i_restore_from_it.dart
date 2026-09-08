import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I restore from it
Future<void> iRestoreFromIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('restore-it')));
  await World.settle(tester);
}
