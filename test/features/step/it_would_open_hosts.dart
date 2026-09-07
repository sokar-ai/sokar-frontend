import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it would open {'3'} hosts
Future<void> itWouldOpenHosts(WidgetTester tester, String count) async {
  expect(World.egress.preview!.opens, hasLength(int.parse(count)));

  // The hosts themselves, not a count and not the set's name: adding one set opens eleven, and
  // whoever presses the button is entitled to see which. **In the order they were given** — the
  // first grant wins, so the order says where each came from and sorting destroys the answer.
  final shown = tester
      .widgetList<Text>(find.byType(Text))
      .map((each) => each.data ?? '')
      .where((line) => line.startsWith('+ '))
      .map((line) => line.substring(2).trim().split(RegExp(r'\s{2,}')).first)
      .toList();
  expect(shown, World.egress.preview!.opens.map((host) => host.host).toList());
}
