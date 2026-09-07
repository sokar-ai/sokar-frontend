import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: what was copied mentions {'lib/money.dart'}
Future<void> whatWasCopiedMentions(WidgetTester tester, String words) async {
  expect(World.copied.join('\n'), contains(words));
}
