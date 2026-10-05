import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I narrow the work to every project
Future<void> iNarrowTheWorkToEveryProject(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('work-project-all')));
  await World.settle(tester);
}
