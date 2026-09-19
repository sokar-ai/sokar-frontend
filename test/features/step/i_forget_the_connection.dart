import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I forget the connection {'ssh://github.com'}
Future<void> iForgetTheConnection(WidgetTester tester, String match) async {
  await tester.tap(find.byKey(ValueKey<String>('forget $match')));
  await World.settle(tester);
}
