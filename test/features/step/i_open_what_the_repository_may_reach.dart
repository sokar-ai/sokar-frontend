import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open what the repository {'payments-api'} may reach
Future<void> iOpenWhatTheRepositoryMayReach(WidgetTester tester, String repository) async {
  await tester.tap(find.byKey(Key('reach-$repository')));
  await World.settle(tester);
}
