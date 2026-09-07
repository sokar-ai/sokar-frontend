import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I continue this work
Future<void> iContinueThisWork(WidgetTester tester) =>
    iChooseTheCommand(tester, 'Continue this work with a new prompt');
