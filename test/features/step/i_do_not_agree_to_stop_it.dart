import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I do not agree to stop it
Future<void> iDoNotAgreeToStopIt(WidgetTester tester) async {
  await tester.tap(find.text('Cancel'));
  await World.settle(tester);
}
