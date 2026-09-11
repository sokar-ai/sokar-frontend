import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I select the work {'sokar-checkout-shell'}
Future<void> iSelectTheWork(WidgetTester tester, String work) async {
  await tapOnScreen(
      tester, find.descendant(of: tileFor(work), matching: find.byKey(const Key('tile-headline'))));
  await World.settle(tester);
}
