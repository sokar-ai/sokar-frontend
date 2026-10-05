import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I name the user {'me'}
Future<void> iNameTheUser(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('connection-user')), name);
  await World.settle(tester);
}
