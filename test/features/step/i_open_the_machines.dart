import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the machines
///
/// Behind the menu button, where a narrow window keeps them.
Future<void> iOpenTheMachines(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await World.settle(tester);
}
