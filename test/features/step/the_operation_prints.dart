import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the operation prints {'Building the image'}
Future<void> theOperationPrints(WidgetTester tester, String line) async {
  World.backend.launch.add(line);
  await World.settle(tester);
}
