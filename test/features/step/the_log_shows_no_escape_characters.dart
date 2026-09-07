import 'package:flutter_test/flutter_test.dart';

import 'the_log_prints_a_red_line_saying.dart';
import 'the_log_shows.dart';

/// Usage: the log shows no escape characters
Future<void> theLogShowsNoEscapeCharacters(WidgetTester tester) async {
  // A log with the escapes left in is unreadable; one with them stripped loses what the colour
  // was carrying. Neither is acceptable, so they are rendered and never printed.
  expect(logText(tester), isNot(contains(ansiEscape)));
}
