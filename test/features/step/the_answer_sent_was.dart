import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the answer sent was {'allow'}
Future<void> theAnswerSentWas(WidgetTester tester, String answer) async {
  // What went down the socket. Allowing and denying differ by one boolean, and the answer has to
  // reach the work that is waiting rather than the screen.
  expect(World.backend.decisions, hasLength(1));
  expect(World.backend.decisions.single.allow, answer == 'allow');
}
