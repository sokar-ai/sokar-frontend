import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show what the repository {'payments-api'} would open
Future<void> iShowWhatTheRepositoryWouldOpen(WidgetTester tester, String repository) async {
  await tester.tap(find.byKey(Key('opens-$repository')));
  await World.settle(tester);
}
