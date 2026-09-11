import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I hide the projects of {'this machine'}
Future<void> iHideTheProjectsOf(WidgetTester tester, String machine) async {
  await tapOnScreen(tester, find.byKey(ValueKey<String>('tree-toggle $machine')));
  await World.settle(tester);
}
