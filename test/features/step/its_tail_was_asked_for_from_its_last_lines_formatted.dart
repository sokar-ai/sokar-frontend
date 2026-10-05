import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: its tail was asked for from its last {20} lines, formatted
Future<void> itsTailWasAskedForFromItsLastLinesFormatted(WidgetTester tester, int lines) async {
  final asked = World.backend.tailsAsked.where((each) => each.formatted).toList();
  expect(asked, isNotEmpty);
  expect(asked.every((each) => each.last == lines && each.log == 'task.log'), isTrue);
}
