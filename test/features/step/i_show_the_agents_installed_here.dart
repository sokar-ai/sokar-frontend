import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I show the agents installed here
Future<void> iShowTheAgentsInstalledHere(WidgetTester tester) =>
    iChooseTheCommand(tester, 'Show the agents installed here');
