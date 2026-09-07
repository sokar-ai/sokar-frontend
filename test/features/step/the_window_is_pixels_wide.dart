import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the window is {360} pixels wide
Future<void> theWindowIsPixelsWide(WidgetTester tester, num width) async {
  tester.view.physicalSize = Size(width.toDouble(), 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await World.settle(tester);
}
