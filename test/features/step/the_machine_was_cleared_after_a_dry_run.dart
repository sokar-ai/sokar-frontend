import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was cleared {'everything'}, after a dry run
///
/// What was cleared: {'everything'}, or a project's name.
Future<void> theMachineWasClearedAfterADryRun(WidgetTester tester, String what) async {
  final clears = World.backend.clears;
  expect(clears.length, greaterThanOrEqualTo(2));
  expect(clears.first.dryRun, isTrue, reason: 'what goes is listed before anything is done');
  expect(clears.last.dryRun, isFalse);
  expect(clears.last.project, what == 'everything' ? isNull : what);
}
