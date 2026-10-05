import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// The escape an agent's own output arrives carrying, spelled out so it survives an editor.
const ansiEscape = '\u001B';

/// Usage: the log prints a red line saying {'it went wrong'}
Future<void> theLogPrintsARedLineSaying(WidgetTester tester, String line) async {
  World.backend.tailing.add(<String>['$ansiEscape[31m$line$ansiEscape[0m']);
  await World.settle(tester);
}
