import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I refresh every machine
Future<void> iRefreshEveryMachine(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('refresh-all')));
  await World.settle(tester);
}
