import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the file {'lib/money.g.dart'} is under what is almost never a finding
Future<void> theFileIsUnderWhatIsAlmostNeverAFinding(WidgetTester tester, String path) async {
  // Last, below its own heading, and there to be read: never hidden.
  final heading = tester.getTopLeft(find.byKey(const Key('review-volume'))).dy;
  final file = tester.getTopLeft(find.byKey(ValueKey<String>('review-file $path'))).dy;
  expect(file, greaterThan(heading));
}
