import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I also delete its key
Future<void> iAlsoDeleteItsKey(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('forget-key')));
  await World.settle(tester);
}
