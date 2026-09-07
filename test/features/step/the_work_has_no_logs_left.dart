import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the work has no logs left
Future<void> theWorkHasNoLogsLeft(WidgetTester tester) async {
  // What a task whose state directory is gone answers, which is what stopping with purge does.
  World.backend.theLogsItHas = <String>{};
}
