import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log keeps {'5000'} lines
Future<void> theLogKeepsLines(WidgetTester tester, String count) async {
  expect(World.logs.all.single.lines, hasLength(int.parse(count)));
}
