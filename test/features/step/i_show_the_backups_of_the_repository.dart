import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show the backups of the repository {'payments-api'}
Future<void> iShowTheBackupsOfTheRepository(WidgetTester tester, String repository) async {
  await tester.tap(find.byKey(Key('backups-$repository')));
  await World.settle(tester);
}
