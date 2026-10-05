import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the agent {'An Agent'}
Future<void> iOpenTheAgent(WidgetTester tester, String agent) async {
  await tester.tap(find.text(agent).first);
  await World.settle(tester);
}
