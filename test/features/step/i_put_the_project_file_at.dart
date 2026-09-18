import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I put the project file at {'/home/somebody/work/new-thing/project.yml'}
Future<void> iPutTheProjectFileAt(WidgetTester tester, String file) async {
  await tester.tap(find.byKey(const Key('project-file-elsewhere')));
  await World.settle(tester);
  await tester.enterText(find.byKey(const Key('project-file')), file);
  await World.settle(tester);
}
