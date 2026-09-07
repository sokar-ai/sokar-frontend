import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log ends
Future<void> theLogEnds(WidgetTester tester) async {
  await World.backend.tailing.close();
  await World.settle(tester);
}
