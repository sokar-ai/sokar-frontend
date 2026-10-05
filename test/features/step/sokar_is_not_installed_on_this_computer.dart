import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: Sokar is not installed on this computer
Future<void> sokarIsNotInstalledOnThisComputer(WidgetTester tester) async {
  World.sokarIsInstalledHere = false;
}
