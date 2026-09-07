import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_choose_the_command.dart';

/// Usage: I ask to close it
Future<void> iAskToCloseIt(WidgetTester tester) async {
  await iChooseTheCommand(tester, 'Quit');
  await World.settle(tester);
}
