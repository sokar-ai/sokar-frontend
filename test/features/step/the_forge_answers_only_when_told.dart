import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge answers only when told
Future<void> theForgeAnswersOnlyWhenTold(WidgetTester tester) async {
  World.forge.answersLater = Completer<void>();
}
