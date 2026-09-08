import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I leave the session
Future<void> iLeaveTheSession(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('leave-session')));
  await World.settle(tester);
}
