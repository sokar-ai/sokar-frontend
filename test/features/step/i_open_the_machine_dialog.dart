import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the machine dialog
Future<void> iOpenTheMachineDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Watch another machine…'));
  await World.settle(tester);
}
