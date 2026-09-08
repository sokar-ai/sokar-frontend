import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I answer the project questions
Future<void> iAnswerTheProjectQuestions(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('project-file')), '/srv/new/project.yml');
  await tester.enterText(find.byKey(const Key('project-name')), 'new-thing');
  await tester.tap(find.byKey(const Key('class-guarded')));
  await tester.enterText(find.byKey(const Key('base-image')), 'ubuntu:24.04');
  // The check is asked once typing settles rather than on every keystroke, so this waits for it.
  await World.settle(tester);
  await tester.pump(const Duration(milliseconds: 500));
  await World.settle(tester);
}
