import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I mark the notice about {'this machine'} as seen
Future<void> iMarkTheNoticeAboutAsSeen(WidgetTester tester, String machine) async {
  await tester.tap(find.byKey(ValueKey<String>('notice-seen $machine')));
  await World.settle(tester);
}
