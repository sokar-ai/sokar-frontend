import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I take the rewritten history
Future<void> iTakeTheRewrittenHistory(WidgetTester tester) async {
  await World.tapInView(tester, 'follow-accept-rewrite');
}
