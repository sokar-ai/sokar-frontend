import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I ask to recreate the selected work
Future<void> iAskToRecreateTheSelectedWork(WidgetTester tester) =>
    iChooseTheCommand(tester, 'Recreate it, so it picks up a newly built environment');
