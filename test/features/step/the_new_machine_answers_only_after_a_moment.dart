import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the new machine answers only after a moment
Future<void> theNewMachineAnswersOnlyAfterAMoment(WidgetTester tester) async {
  World.backend.answersLater = Completer<void>();
}
