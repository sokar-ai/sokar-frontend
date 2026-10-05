import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I say the user that runs work is {'builder'}
Future<void> iSayTheUserThatRunsWorkIs(WidgetTester tester, String user) async {
  await tester.enterText(find.byKey(const Key('work-user-name')), user);
  await World.settle(tester);
}
