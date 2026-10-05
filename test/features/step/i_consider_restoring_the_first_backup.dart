import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I consider restoring the first backup
Future<void> iConsiderRestoringTheFirstBackup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('consider-restoring')).first);
  await World.settle(tester);
}
