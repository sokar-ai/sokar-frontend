import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go back
Future<void> iGoBack(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('wizard-back')));
  await World.settle(tester);
}
