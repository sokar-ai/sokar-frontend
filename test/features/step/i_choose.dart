import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose {'Leave it alone'}
Future<void> iChoose(WidgetTester tester, String words) async {
  await tester.tap(find.text(words));
  await World.settle(tester);
}
