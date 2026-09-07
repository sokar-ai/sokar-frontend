import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Usage: the window is {360} pixels wide
Future<void> theWindowIsPixelsWide(WidgetTester tester, num width) async {
  await tester.binding.setSurfaceSize(Size(width.toDouble(), 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpAndSettle();
}
