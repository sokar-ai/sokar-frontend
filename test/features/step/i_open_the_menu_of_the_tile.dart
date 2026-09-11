import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I open the menu of the tile {'sokar-checkout-shell'}
Future<void> iOpenTheMenuOfTheTile(WidgetTester tester, String work) async {
  await tester.tap(find.descendant(of: tileFor(work), matching: find.byKey(const Key('tile-menu'))));
  await World.settle(tester);
}
