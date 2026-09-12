import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I do not agree to start it
Future<void> iDoNotAgreeToStartIt(WidgetTester tester) async {
  await tester.tap(find.text('Cancel'));
  await World.settle(tester);
}
