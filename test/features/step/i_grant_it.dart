import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I grant it
Future<void> iGrantIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('widen-apply')));
  await World.settle(tester);
}
