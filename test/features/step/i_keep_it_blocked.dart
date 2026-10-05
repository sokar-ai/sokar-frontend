import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I keep it blocked
Future<void> iKeepItBlocked(WidgetTester tester) async {
  await tester.tap(find.text('Keep it blocked'));
  await World.settle(tester);
}
