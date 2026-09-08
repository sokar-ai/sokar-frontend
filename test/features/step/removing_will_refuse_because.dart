import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: removing will refuse because {'HOLDS_WORK'}
Future<void> removingWillRefuseBecause(WidgetTester tester, String outcome) async {
  World.backend.deletionAnswers = DeleteOutcome(outcome);
}
