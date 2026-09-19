import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I send the key {'id_work'} to the machine
Future<void> iSendTheKeyToTheMachine(WidgetTester tester, String name) async {
  // The desktop's file dialog, answered with that key of this computer.
  World.pickedFile = '${World.setup.home.path}/.ssh/$name';
  await World.tapInView(tester, 'store-choose-file');
}
