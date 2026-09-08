import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I show the protected store
Future<void> iShowTheProtectedStore(WidgetTester tester) =>
    iChooseTheCommand(tester, 'Show the protected store');
