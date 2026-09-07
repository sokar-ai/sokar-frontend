import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it shows the destination {'api.example.test:443'}
Future<void> itShowsTheDestination(WidgetTester tester, String where) async {
  final shown = tester.widget<Text>(find.byKey(const Key('blocked-destination')));
  expect(shown.data, where);
}
