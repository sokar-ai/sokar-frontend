import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: somebody acts on what they were told
Future<void> somebodyActsOnWhatTheyWereTold(WidgetTester tester) async {
  World.notifier.act();
  await World.settle(tester);
}
