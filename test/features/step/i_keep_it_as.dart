import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I keep it as {'nightly-tests'}
Future<void> iKeepItAs(WidgetTester tester, String name) async {
  await World.openMoreOptions(tester);
  await tester.enterText(find.byKey(const Key('template-name')), name);
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('template-keep')));
  await World.settle(tester);
}
