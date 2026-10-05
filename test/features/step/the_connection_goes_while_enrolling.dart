import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the connection goes while enrolling
Future<void> theConnectionGoesWhileEnrolling(WidgetTester tester) async {
  World.backend.enrollingLosesTheConnection = true;
}
