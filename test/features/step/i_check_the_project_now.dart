import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I check the project now
Future<void> iCheckTheProjectNow(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('project-check-now')));
  await tester.tap(find.byKey(const Key('project-check-now')));
  await World.settle(tester);
}
