import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the failed operation from what needs a person
Future<void> iOpenTheFailedOperationFromWhatNeedsAPerson(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('failed-operation-open')).first);
  await World.settle(tester);
}
