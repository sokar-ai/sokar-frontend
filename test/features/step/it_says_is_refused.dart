import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it says {'telemetry.example.test'} is refused
Future<void> itSaysIsRefused(WidgetTester tester, String host) async {
  // "We said no" and "nobody added it" look identical to a dropped packet, and only one of them
  // is somebody's decision.
  final refused = tester.widgetList<Text>(find.byKey(const Key('refused-host')));
  expect(refused.map((each) => each.data), contains(host));
}
