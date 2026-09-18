import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I say it is called {'the build machine'}
Future<void> iSayItIsCalled(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('machine-name')), name);
  await World.settle(tester);
}
