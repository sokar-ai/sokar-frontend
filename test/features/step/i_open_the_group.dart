import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the group {'stopped'}
Future<void> iOpenTheGroup(WidgetTester tester, String group) async {
  final heading = find.byKey(ValueKey<String>('work-group-fold $group'));
  await tester.ensureVisible(heading);
  await tester.tap(heading);
  await World.settle(tester);
}
