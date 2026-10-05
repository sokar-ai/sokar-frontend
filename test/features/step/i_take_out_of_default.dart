import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I take {'api'} out of default
Future<void> iTakeOutOfDefault(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey<String>('default-remove $name')));
  await World.settle(tester);
}
