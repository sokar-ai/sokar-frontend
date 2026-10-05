import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log prints {'6000'} lines at once
Future<void> theLogPrintsLinesAtOnce(WidgetTester tester, String count) async {
  World.backend.tailing.add(<String>[for (var at = 1; at <= int.parse(count); at++) 'line $at']);
  await World.settle(tester);
}
