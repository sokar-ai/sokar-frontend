import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: nothing asks what it can install
Future<void> nothingAsksWhatItCanInstall(WidgetTester tester) async {
  expect(find.byKey(const Key('list-packages')), findsNothing);
}
