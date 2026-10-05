import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: opening the page is not offered
Future<void> openingThePageIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('grant-dialog')), findsOneWidget);
  expect(find.byKey(const Key('grant-open')), findsNothing);
}
