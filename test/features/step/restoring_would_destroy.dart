import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: restoring would destroy {'migrate'}
Future<void> restoringWouldDestroy(WidgetTester tester, String ref) async {
  World.backend.theRestoreWouldDestroy = <String>[ref];
}
