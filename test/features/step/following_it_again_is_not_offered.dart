import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: following it again is not offered
Future<void> followingItAgainIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('follow-it')), findsNothing);
}
