import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I am done with the new project
Future<void> iAmDoneWithTheNewProject(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('done-creating')));
  await World.settle(tester);
}
