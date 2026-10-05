import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I ask to stop everything
Future<void> iAskToStopEverything(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('stop-everything')));
  await World.settle(tester);
}
