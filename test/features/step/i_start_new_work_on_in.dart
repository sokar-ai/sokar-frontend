import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_start_new_work.dart';

/// Usage: I start new work on {'this machine'} in {'checkout'}
Future<void> iStartNewWorkOnIn(WidgetTester tester, String machine, String project) async {
  await iStartNewWork(tester);
  final where = find.byKey(ValueKey<String>('new-work-on $machine'));
  if (where.evaluate().isNotEmpty) {
    await tester.tap(where);
    await World.settle(tester);
  }
  await tester.tap(find.byKey(ValueKey<String>('new-work-in $project')));
  await World.settle(tester);
}
