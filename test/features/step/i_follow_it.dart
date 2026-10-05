import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I follow it
Future<void> iFollowIt(WidgetTester tester) async {
  await World.tapInView(tester, 'follow-it');
}
