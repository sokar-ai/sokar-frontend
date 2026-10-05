import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I give a new password
Future<void> iGiveANewPassword(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('join-reset')));
  await World.settle(tester);
}
