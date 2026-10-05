import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the review shows {'(value * 100).round()'}
Future<void> theReviewShows(WidgetTester tester, String line) async {
  // Opened first: thirty files all expanded is a review nobody reads to the end, so a file shows
  // its hunks only when it is asked to.
  await tester.tap(find.text('lib/money.dart'));
  await World.settle(tester);

  final shown = tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((each) => each.data ?? '')
      .join('\n');
  expect(shown, contains(line));
}
