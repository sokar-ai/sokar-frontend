import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log prints {'building the image'}
Future<void> theLogPrints(WidgetTester tester, String line) async {
  World.backend.tailing.add(<String>[line]);
  await World.settle(tester);
}
