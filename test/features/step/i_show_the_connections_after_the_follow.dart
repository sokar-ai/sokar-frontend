import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show the connections after the follow
Future<void> iShowTheConnectionsAfterTheFollow(WidgetTester tester) async {
  await World.tapInView(tester, 'follow-show-connections');
}
