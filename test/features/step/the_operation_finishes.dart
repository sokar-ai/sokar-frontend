import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the operation finishes
Future<void> theOperationFinishes(WidgetTester tester) async {
  await World.backend.launch.close();
  await World.settle(tester);
}
