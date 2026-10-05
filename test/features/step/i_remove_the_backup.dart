import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I remove the backup
Future<void> iRemoveTheBackup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('remove-the-backup')));
  await World.settle(tester);
}
