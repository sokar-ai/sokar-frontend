import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose {'Leave it alone'}
Future<void> iChoose(WidgetTester tester, String words) async {
  // An option of a drop-down is chosen from the list it opens; anything else is pressed.
  await World.chooseWords(tester, words);
}
