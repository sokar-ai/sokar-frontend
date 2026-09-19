import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show its connection from the follow
Future<void> iShowItsConnectionFromTheFollow(WidgetTester tester) async {
  await World.tapInView(tester, 'follow-show-connection');
}
