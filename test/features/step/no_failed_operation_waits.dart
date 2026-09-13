import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: no failed operation waits
Future<void> noFailedOperationWaits(WidgetTester tester) async {
  expect(
    find.byWidgetPredicate((widget) => widget is Card && '${widget.key}'.contains("'failed-operation ")),
    findsNothing,
  );
}
