import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_choose_the_command.dart';

/// Usage: I shut the store from the machine's menu
Future<void> iShutTheStoreFromTheMachinesMenu(WidgetTester tester) async {
  await iChooseTheCommand(tester, 'Shut the vault');
  await tester.tap(find.byKey(const Key('vault-confirm')));
  await World.settle(tester);
}
