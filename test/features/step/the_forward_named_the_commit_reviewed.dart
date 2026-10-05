import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forward named the commit reviewed {'9a3c1f2e4b5d6a7c8e9f0a1b2c3d4e5f6a7b8c9d'}
///
/// A push that moved after its review is then refused by the machine, not forwarded unseen.
Future<void> theForwardNamedTheCommitReviewed(WidgetTester tester, String commit) async {
  expect(World.backend.approvedCommits.last, commit);
}
