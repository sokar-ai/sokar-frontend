import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine refuses the name {'login-7'} saying {'kept for login containers'}
Future<void> theMachineRefusesTheNameSaying(WidgetTester tester, String name, String words) async {
  World.backend.refusedName = (name: name, words: words);
}
