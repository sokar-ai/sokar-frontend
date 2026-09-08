import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I keep the backup
Future<void> iKeepTheBackup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('keep-the-backup')));
  await World.settle(tester);
}
