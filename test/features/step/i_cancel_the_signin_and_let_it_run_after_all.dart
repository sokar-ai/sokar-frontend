import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I cancel the sign-in and let it run after all
Future<void> iCancelTheSigninAndLetItRunAfterAll(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('unlock-cancel')));
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('unlock-cancel-no')));
  await World.settle(tester);
}
