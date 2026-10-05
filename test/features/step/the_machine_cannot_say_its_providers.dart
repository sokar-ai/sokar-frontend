import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine cannot say its providers
Future<void> theMachineCannotSayItsProviders(WidgetTester tester) async {
  World.backend.providersRefused = true;
}
