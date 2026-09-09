import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the work also has the log {'events.jsonl'}
Future<void> theWorkAlsoHasTheLog(WidgetTester tester, String log) async {
  // Which files a task has is the daemon's answer and nothing this end decides — a rule that only
  // holds while nothing here narrows the answer by what a file is called.
  World.backend.theLogsItHas = <String>{...World.backend.theLogsItHas, log};
}
