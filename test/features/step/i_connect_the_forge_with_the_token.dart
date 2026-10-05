import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I connect the forge with the token {'ghp_accepted'}
Future<void> iConnectTheForgeWithTheToken(WidgetTester tester, String token) async {
  await tester.enterText(find.byKey(const Key('forge-token')), token);
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('forge-connect')));
  await World.settle(tester);
}
