import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the destination cannot be written yet
Future<void> theDestinationCannotBeWrittenYet(WidgetTester tester) async {
  final write = tester.widget<FilledButton>(find.byKey(const Key('write-destination')));
  expect(write.onPressed, isNull);
}
