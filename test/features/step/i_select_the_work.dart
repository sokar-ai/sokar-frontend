import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I select the work {'sokar-checkout-shell'}
Future<void> iSelectTheWork(WidgetTester tester, String work) async {
  await tester.tap(find.text(work));
  await World.settle(tester);
}
