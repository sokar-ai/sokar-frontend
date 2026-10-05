import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: opening the page waits for its answer's way back
Future<void> openingThePageWaitsForItsAnswersWayBack(WidgetTester tester) async {
  expect(tester.widget<FilledButton>(find.byKey(const Key('grant-open'))).onPressed, isNull);
}
