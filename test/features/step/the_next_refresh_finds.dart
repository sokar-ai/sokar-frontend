import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the next refresh finds {'VAULT_LOCKED'}
Future<void> theNextRefreshFinds(WidgetTester tester, String outcome) async {
  World.backend.nextRefreshFinds = outcome;
}
