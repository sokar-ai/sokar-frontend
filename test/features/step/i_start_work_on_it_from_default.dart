import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start work on it from default
Future<void> iStartWorkOnItFromDefault(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('default-start-new')));
  await World.settle(tester);
}
