import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I set it up and connect
Future<void> iSetItUpAndConnect(WidgetTester tester) async {
  await World.tapInView(tester, 'finish-setup');
}
