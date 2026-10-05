import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I open my forges
Future<void> iOpenMyForges(WidgetTester tester) =>
    iChooseTheCommand(tester, 'Your forges: where your repositories are, and their tokens');
