import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I take it back
Future<void> iTakeItBack(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('narrow-apply')));
  await World.settle(tester);
}
