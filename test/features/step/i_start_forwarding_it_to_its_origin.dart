import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start forwarding it to its origin
Future<void> iStartForwardingItToItsOrigin(WidgetTester tester) async {
  await tester.tap(find.text('Forward it to its origin…'));
  await World.settle(tester);
}
