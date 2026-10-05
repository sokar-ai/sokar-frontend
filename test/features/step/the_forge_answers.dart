import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge answers
Future<void> theForgeAnswers(WidgetTester tester) async {
  World.forge.answersLater!.complete();
  await World.settle(tester);
}
