import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I forget it
Future<void> iForgetIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('forget-it')));
  await World.settle(tester);
}
