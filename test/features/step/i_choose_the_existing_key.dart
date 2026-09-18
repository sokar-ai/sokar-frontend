import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the existing key {'id_ed25519'}
Future<void> iChooseTheExistingKey(WidgetTester tester, String name) async {
  await World.tapInView(tester, 'existing-key');
  await tester.tap(find.text(name).last);
  await World.settle(tester);
  await World.tapInView(tester, 'use-existing-key');
}
