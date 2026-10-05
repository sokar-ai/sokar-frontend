import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I narrow the work to the project {'billing'}
Future<void> iNarrowTheWorkToTheProject(WidgetTester tester, String project) async {
  await tester.tap(find.byKey(ValueKey<String>('work-project $project')));
  await World.settle(tester);
}
