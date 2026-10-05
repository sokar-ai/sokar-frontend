import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I search the repositories for {'web'}
Future<void> iSearchTheRepositoriesFor(WidgetTester tester, String typed) async {
  await tester.enterText(find.byKey(const Key('repositories-search')), typed);
  await World.settle(tester);
}
