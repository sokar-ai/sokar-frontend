import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_bind_the_machine_to.dart';
import 'i_choose_the_command.dart';

/// Usage: I bind it again
///
/// The start form that followed the first binding is put away, and the same repository is bound again
/// from the list, as a person would.
Future<void> iBindItAgain(WidgetTester tester) async {
  for (final key in <String>['start-not-now', 'binding-close', 'repositories-close']) {
    if (find.byKey(Key(key)).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(Key(key)).last);
      await World.settle(tester);
    }
  }
  await iChooseTheCommand(tester, 'A project from a repository you have');
  await iBindTheMachineTo(tester, 'acme/api');
}
