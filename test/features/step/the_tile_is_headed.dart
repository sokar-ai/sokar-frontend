import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the tile {'sokar-shared-shell'} is headed {'elsewhere'}
Future<void> theTileIsHeaded(WidgetTester tester, String work, String machine) async {
  final heading = tester.widget<Text>(
      find.descendant(of: tileFor(work), matching: find.byKey(const Key('tile-machine'))));
  expect(heading.data, machine);
  expect(heading.style?.fontWeight, FontWeight.bold);
}
