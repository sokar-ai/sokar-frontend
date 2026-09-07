import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go to what is blocked
Future<void> iGoToWhatIsBlocked(WidgetTester tester) async {
  await tester.tap(find.text('Blocked'));
  await World.settle(tester);
}
