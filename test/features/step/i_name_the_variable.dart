import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I name the variable {'GITLAB_TOKEN'}
Future<void> iNameTheVariable(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('connection-variable')), name);
  await World.settle(tester);
}
