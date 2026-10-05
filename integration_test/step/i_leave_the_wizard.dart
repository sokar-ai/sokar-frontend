import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: I leave the wizard
Future<void> iLeaveTheWizard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('connection-leave')));
  await pumpFor(tester);
}
