import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the menu {'Options'}
Future<void> iOpenTheMenu(WidgetTester tester, String menu) async {
  await tester.tap(find.byTooltip(menu));
  await World.settle(tester);
}
