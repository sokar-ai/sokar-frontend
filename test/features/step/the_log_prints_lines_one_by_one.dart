import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log prints {'400'} lines one by one
///
/// A log written hard: each line on its own, faster than frames are drawn.
Future<void> theLogPrintsLinesOneByOne(WidgetTester tester, String count) async {
  final lines = int.parse(count);
  var builds = 0;
  void counted() => builds++;
  World.logs.addListener(counted);
  for (var at = 1; at <= lines; at++) {
    World.backend.tailing.add(<String>['line $at of a log written hard']);
    // A line every two milliseconds: ten times faster than the frames the view is drawn in.
    await tester.pump(const Duration(milliseconds: 2));
  }
  await World.settle(tester);
  World.logs.removeListener(counted);
  // Drawn in bundles, not once per line: 400 lines over 0.8 s are a handful of redraws.
  expect(builds, lessThan(lines ~/ 20), reason: 'the view was redrawn $builds times for $lines lines');
}
