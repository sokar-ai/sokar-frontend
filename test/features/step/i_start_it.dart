import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start it
Future<void> iStartIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-go')));
  await World.settle(tester);
}
