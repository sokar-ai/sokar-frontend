import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine will keep the parts but never place the file
Future<void> theMachineWillKeepThePartsButNeverPlaceTheFile(WidgetTester tester) async {
  World.backend.neverPlaces = true;
}
