import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start work in default on the one called {'tools'}
Future<void> iStartWorkInDefaultOnTheOneCalled(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey<String>('default-start $name')));
  await World.settle(tester);
}
