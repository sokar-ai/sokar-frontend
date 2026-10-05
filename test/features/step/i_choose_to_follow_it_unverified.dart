import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose to follow it unverified
Future<void> iChooseToFollowItUnverified(WidgetTester tester) async {
  await World.pick(tester, 'follow-unverified');
}
