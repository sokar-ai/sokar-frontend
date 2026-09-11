import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I show what is running
Future<void> iShowWhatIsRunning(WidgetTester tester) async {
  await tapOnScreen(tester, find.byKey(ValueKey<String>('tree-running ${World.machines.current.name}')));
  await World.settle(tester);
}
