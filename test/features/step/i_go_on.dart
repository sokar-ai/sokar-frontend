import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go on
Future<void> iGoOn(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('wizard-next')));
  await World.settle(tester);
}
