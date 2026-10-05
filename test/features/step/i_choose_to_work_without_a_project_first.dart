import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose to work without a project first
Future<void> iChooseToWorkWithoutAProjectFirst(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('first-no-project')));
  await World.settle(tester);
}
