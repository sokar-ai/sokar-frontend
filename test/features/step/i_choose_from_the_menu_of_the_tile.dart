import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I choose {'Stop it and remove it'} from the menu of the tile {'sokar-shared-shell'}
Future<void> iChooseFromTheMenuOfTheTile(WidgetTester tester, String label, String work) async {
  await tester.tap(find.descendant(of: tileFor(work), matching: find.byKey(const Key('tile-menu'))));
  await World.settle(tester);
  await tester.tap(find.ancestor(
      of: find.text(label), matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem)));
  await World.settle(tester);
}
