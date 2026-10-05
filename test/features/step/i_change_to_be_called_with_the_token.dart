import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I change {'GitHub'} to be called {'GitHub private'} with the token {'ghp_renewed'}
Future<void> iChangeToBeCalledWithTheToken(WidgetTester tester, String name, String renamed, String token) async {
  await World.settle(tester);
  // From its menu on the Forges page, or a form already open (a binding asks for it in place).
  if (find.byKey(const Key('forge-name')).evaluate().isEmpty) {
    await tester.tap(find.byKey(ValueKey<String>('forges-menu $name')).first);
    await World.settle(tester);
    await tester.tap(find.byKey(ValueKey<String>('forge-change $name')));
    await World.settle(tester);
  }
  await tester.enterText(find.byKey(const Key('forge-name')), renamed);
  await tester.enterText(find.byKey(const Key('forge-token')), token);
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('forge-connect')));
  await World.settle(tester);
}
