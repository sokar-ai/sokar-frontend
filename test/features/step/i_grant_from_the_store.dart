import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_show_the_vault.dart';

/// Usage: I grant {'jira'} from the store
Future<void> iGrantFromTheStore(WidgetTester tester, String name) async {
  await iShowTheVault(tester);
  await tester.tap(find.byKey(ValueKey<String>('grant $name')));
  await World.settle(tester);
}
