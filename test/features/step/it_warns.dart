import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it warns {'the gate now rests on the container holding no credential'}
Future<void> itWarns(WidgetTester tester, String words) async {
  final said = tester.widget<Text>(find.byKey(const Key('egress-cost')));
  expect(said.data, contains(words));
}
