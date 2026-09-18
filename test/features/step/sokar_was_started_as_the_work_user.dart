import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: Sokar was started as the work user
Future<void> sokarWasStartedAsTheWorkUser(WidgetTester tester) async {
  expect(World.setup.asUserRan, contains('systemctl --user enable --now sokard'));
  expect(World.setup.asRootRan.where((script) => script.contains('systemctl --user')), isEmpty,
      reason: "root started another user's service");
}
