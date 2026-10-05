import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the first session was left
Future<void> theFirstSessionWasLeft(WidgetTester tester) async {
  expect(World.terminals.length, greaterThanOrEqualTo(2), reason: 'only one session was ever opened');
  expect(World.terminals.first.closed, isTrue, reason: 'the first way in is still open');
}
