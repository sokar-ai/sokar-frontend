import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I consider removing the first backup
Future<void> iConsiderRemovingTheFirstBackup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('consider-removing')).first);
  await World.settle(tester);
}
