import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I look at the forge's repository {'acme/api'}
Future<void> iLookAtTheForgesRepository(WidgetTester tester, String name) async {
  await chooseTheRepository(tester, name);
}

/// Chooses [what] (`bind`, `repository-tools`, `open-at-forge`) from [repository]'s menu on its forge's page.
Future<void> fromTheRepositorysMenu(WidgetTester tester, String repository, String what) async {
  await tester.tap(find.byKey(ValueKey<String>('forge-repository-menu $repository')));
  await World.settle(tester);
  await tester.tap(find.byKey(ValueKey<String>('$what $repository')));
  await World.settle(tester);
}

/// Chooses [name] in the list, as a person does before anything is offered for it.
Future<void> chooseTheRepository(WidgetTester tester, String name) async {
  await tester.tap(find.descendant(of: find.byKey(ValueKey<String>('repository $name')), matching: find.text(name)));
  await World.settle(tester);
}
