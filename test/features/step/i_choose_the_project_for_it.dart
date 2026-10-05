import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the project {'billing'} for it
Future<void> iChooseTheProjectForIt(WidgetTester tester, String project) async {
  await tester.tap(find.byKey(ValueKey<String>('new-work-in $project')));
  await World.settle(tester);
}
