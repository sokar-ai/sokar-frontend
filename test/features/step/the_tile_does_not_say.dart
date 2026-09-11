import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the tile {'sokar-checkout-shell'} does not say {'left'}
Future<void> theTileDoesNotSay(WidgetTester tester, String work, String words) async {
  expect(tileFor(work), findsOneWidget, reason: 'no tile for $work');
  expect(find.descendant(of: tileFor(work), matching: find.textContaining(words)), findsNothing);
}
