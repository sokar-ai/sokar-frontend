import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the backend will refuse to stop everything
Future<void> theBackendWillRefuseToStopEverything(WidgetTester tester) async {
  World.backend.refusePanic = true;
}
