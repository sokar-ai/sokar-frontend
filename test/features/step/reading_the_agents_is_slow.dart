import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: reading the agents is slow
Future<void> readingTheAgentsIsSlow(WidgetTester tester) async {
  World.backend.agentsTake = const Duration(seconds: 3);
}
