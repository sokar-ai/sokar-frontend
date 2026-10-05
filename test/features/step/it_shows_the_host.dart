import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it shows the host {'api.anthropic.com'}
Future<void> itShowsTheHost(WidgetTester tester, String host) async {
  // The hosts an agent needs are added to a task's egress on top of the project's own, so what
  // one agent brings with it is worth seeing before choosing it.
  expect(find.byKey(const Key('agent-host')), findsWidgets);
  expect(find.text(host), findsWidgets);
}
