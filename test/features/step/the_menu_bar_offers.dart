import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the menu bar offers {'Machines, Options, About'}
Future<void> theMenuBarOffers(WidgetTester tester, String menus) async {
  final offered = tester
      .widgetList<SubmenuButton>(find.byType(SubmenuButton))
      .map((menu) => (menu.child! as Text).data)
      .join(', ');
  expect(offered, menus);
}
