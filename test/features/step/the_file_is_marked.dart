import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the file {'.github/workflows/ci.yml'} is marked {'dangerous by kind'}
Future<void> theFileIsMarked(WidgetTester tester, String path, String rank) async {
  expect(tester.widget<Text>(find.byKey(ValueKey<String>('review-rank $path'))).data, rank);
}
