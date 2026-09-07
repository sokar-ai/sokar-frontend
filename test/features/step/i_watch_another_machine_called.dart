import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I watch another machine called {'elsewhere'}
Future<void> iWatchAnotherMachineCalled(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  await tester.tap(find.widgetWithText(MenuItemButton, 'Watch another machine…'));
  await World.settle(tester);

  final fields = find.byType(TextField);
  await tester.enterText(fields.first, name);
  await tester.enterText(fields.last, '/tmp/$name.sock');
  await World.settle(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Watch it'));
  await World.settle(tester);
}
