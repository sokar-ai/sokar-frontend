import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine does not choose a place for project files yet
Future<void> theMachineDoesNotChooseAPlaceForProjectFilesYet(WidgetTester tester) async {
  World.backend.choosesNoPlace = true;
}
