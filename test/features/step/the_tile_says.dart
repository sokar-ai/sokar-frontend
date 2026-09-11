import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the tile {'sokar-checkout-shell'} says {'blocked for'}
Future<void> theTileSays(WidgetTester tester, String work, String words) async {
  expect(tileFor(work), findsOneWidget, reason: 'no tile for $work');
  expect(
    find.descendant(of: tileFor(work), matching: find.textContaining(words)),
    findsWidgets,
  );
}
