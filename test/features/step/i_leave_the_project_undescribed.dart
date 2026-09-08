import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I leave the project undescribed
Future<void> iLeaveTheProjectUndescribed(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('abandon-creating')));
  await World.settle(tester);
}
