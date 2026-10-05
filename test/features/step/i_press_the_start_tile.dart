import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I press the start tile
Future<void> iPressTheStartTile(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-work')));
  await World.settle(tester);
}
