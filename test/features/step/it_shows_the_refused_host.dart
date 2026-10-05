import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it shows the refused host {'telemetry.example.test'}
Future<void> itShowsTheRefusedHost(WidgetTester tester, String host) async {
  // Beside what it may reach, not instead of it: "we said no" and "nobody added it" look
  // identical to a dropped packet, and only one of them is somebody's decision.
  expect(find.byKey(const Key('agent-refused')), findsWidgets);
  expect(find.text(host), findsWidgets);
}
