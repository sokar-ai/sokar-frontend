import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I ask to close it
///
/// What the window's own close button does: the desktop asks the app, and the app asks first.
Future<void> iAskToCloseIt(WidgetTester tester) async {
  // ignore: invalid_use_of_protected_member
  World.closing = tester.binding.handleRequestAppExit();
  await World.settle(tester);
}
