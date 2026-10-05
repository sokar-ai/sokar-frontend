import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was forwarded onto {'fix-rounding'}
Future<void> itWasForwardedOnto(WidgetTester tester, String branch) async {
  // What went down the socket. Approve is the only call in the whole contract that sends anything
  // anywhere, and it takes the branch rather than inferring one.
  expect(World.backend.approvals, hasLength(1));
  expect(World.backend.approvals.single.branch, branch);
}
