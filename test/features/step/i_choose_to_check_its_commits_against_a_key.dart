import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose to check its commits against a key
Future<void> iChooseToCheckItsCommitsAgainstAKey(WidgetTester tester) async {
  await World.pick(tester, 'follow-pinned');
}
