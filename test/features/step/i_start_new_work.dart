import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I start new work
Future<void> iStartNewWork(WidgetTester tester) async {
  await toThePlace(tester, 'work');
  await tester.tap(find.byKey(const Key('new-work')));
  await World.settle(tester);
}
