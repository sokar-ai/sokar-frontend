import 'package:flutter_test/flutter_test.dart';

import 'i_choose_the_command.dart';

/// Usage: I ask what this work should read as
Future<void> iAskWhatThisWorkShouldReadAs(WidgetTester tester) async {
  // The label says what it will do, so it changes once a caption is set. Either wording opens the
  // same dialog.
  try {
    await iChooseTheCommand(tester, 'Give this work something to read by');
  } on Object {
    await iChooseTheCommand(tester, 'Change what this work reads as');
  }
}
