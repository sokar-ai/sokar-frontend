import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: Sokar was started as the work user
Future<void> sokarWasStartedAsTheWorkUser(WidgetTester tester) async {
  // Started, then its hooks registered, then asked — in that order, all as the work user.
  final ran = World.setup.asUserRan;
  final started = ran.indexOf('systemctl --user enable --now sokard');
  final registered = ran.indexOf('sokar setup');
  final asked = ran.indexOf('sokar doctor');
  expect(started, isNonNegative, reason: 'Sokar was not started');
  expect(registered, greaterThan(started), reason: 'sokar setup did not run after the start');
  expect(asked, greaterThan(registered), reason: 'sokar doctor was asked before sokar setup');
  expect(World.setup.asRootRan.where((script) => script.contains('systemctl --user') || script.contains('sokar setup')), isEmpty,
      reason: "root started another user's service");
}
