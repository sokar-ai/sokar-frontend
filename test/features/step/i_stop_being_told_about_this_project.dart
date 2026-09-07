import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I stop being told about this project
Future<void> iStopBeingToldAboutThisProject(WidgetTester tester) async {
  await iChooseTheCommand(tester, 'Stop telling me about this project');
}
