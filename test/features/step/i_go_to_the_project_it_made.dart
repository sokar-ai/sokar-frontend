import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go to the project it made
Future<void> iGoToTheProjectItMade(WidgetTester tester) async {
  await World.tapInView(tester, 'follow-done');
}
