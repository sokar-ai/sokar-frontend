import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the log says {'has no log called "nowhere.log"'}
Future<void> theLogSays(WidgetTester tester, String words) async {
  // A name a task does not have is an answer, not a failure of the interface: it is what somebody
  // gets while looking for the right one, so it has to name what failed.
  final problem = tester.widget<Text>(find.byKey(const Key('log-problem')));
  expect(problem.data, contains(words));
}
