import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I agree to stop it
Future<void> iAgreeToStopIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('stop-it')));
  await World.settle(tester);
}
