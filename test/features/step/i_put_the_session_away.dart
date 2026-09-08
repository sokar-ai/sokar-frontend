import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I put the session away
///
/// The header's own control, and not `Escape`: inside a session that key belongs to whatever is
/// running at the far end.
Future<void> iPutTheSessionAway(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Put it away, without leaving it'));
  await World.settle(tester);
}
