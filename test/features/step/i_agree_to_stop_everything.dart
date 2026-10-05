import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I agree to stop everything
Future<void> iAgreeToStopEverything(WidgetTester tester) async {
  // A second, separate act. The first press only asks.
  await tester.tap(find.byKey(const Key('stop-it-all')));
  await World.settle(tester);
}
