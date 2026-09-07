import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I let it through
Future<void> iLetItThrough(WidgetTester tester) async {
  await tester.tap(find.text('Let it through'));
  await World.settle(tester);
}
