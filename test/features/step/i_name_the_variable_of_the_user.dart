import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I name the variable of the user {'GITLAB_USER'}
Future<void> iNameTheVariableOfTheUser(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('connection-user-variable')), name);
  await World.settle(tester);
}
